#!/bin/bash

set -ex

source $(dirname $0)/tc-vars.sh

build_amd64=yes
build_cuda=no
build_arm=no
build_arm64=no

if [ "$1" = "--cuda" ]; then
    build_cuda=yes
    build_arm=no
    build_arm64=no
fi

if [ "$1" = "--arm" ]; then
    build_cuda=no
    build_arm=yes
    build_arm64=no
fi

if [ "$1" = "--arm64" ]; then
    build_cuda=no
    build_arm=no
    build_arm64=yes
fi

pushd ${DS_ROOT_TASK}/DeepSpeech/tf/
    BAZEL_BUILD="bazel ${BAZEL_OUTPUT_USER_ROOT} build -s --explain bazel_monolithic_tf.log --verbose_explanations --experimental_strict_action_env --config=monolithic"

    # Pure amd64 CPU-only build
    if [ "${build_cuda}" = "no" -a "${build_arm}" = "no" -a "${build_arm64}" = "no" ]; then
        echo "" | ./configure && ${BAZEL_BUILD} -c opt ${BAZEL_OPT_FLAGS} ${BAZEL_EXTRA_FLAGS} ${BUILD_TARGET_LIB_CPP_API} ${BUILD_TARGET_GRAPH_TRANSFORMS} ${BUILD_TARGET_GRAPH_SUMMARIZE} ${BUILD_TARGET_GRAPH_BENCHMARK} ${BUILD_TARGET_CONVERT_MMAP} ${BUILD_TARGET_TOCO} ${BUILD_TARGET_LITE_BENCHMARK}
    fi

    # Cross RPi3 CPU-only build
    if [ "${build_arm}" = "yes" ]; then
        echo "" | ./configure && ${BAZEL_BUILD} -c opt ${BAZEL_ARM_FLAGS} ${BAZEL_EXTRA_FLAGS} ${BUILD_TARGET_LIB_CPP_API} ${BUILD_TARGET_GRAPH_TRANSFORMS} ${BUILD_TARGET_GRAPH_SUMMARIZE} ${BUILD_TARGET_GRAPH_BENCHMARK}
    fi

    # Cross ARM64 Cortex-A53 build
    if [ "${build_arm64}" = "yes" ]; then
        echo "" | ./configure && ${BAZEL_BUILD} -c opt ${BAZEL_ARM64_FLAGS} ${BAZEL_EXTRA_FLAGS} ${BUILD_TARGET_LIB_CPP_API} ${BUILD_TARGET_GRAPH_TRANSFORMS} ${BUILD_TARGET_GRAPH_SUMMARIZE} ${BUILD_TARGET_GRAPH_BENCHMARK}
    fi

    # Pure amd64 CUDA-enabled build
    if [ "${build_cuda}" = "yes" ]; then
        eval "export ${TF_CUDA_FLAGS}" && (echo "" | ./configure) && ${BAZEL_BUILD} -c opt ${BAZEL_CUDA_FLAGS} ${BAZEL_EXTRA_FLAGS} ${BAZEL_OPT_FLAGS} ${BUILD_TARGET_LIB_CPP_API} ${BUILD_TARGET_GRAPH_TRANSFORMS} ${BUILD_TARGET_GRAPH_SUMMARIZE} ${BUILD_TARGET_GRAPH_BENCHMARK}
    fi

    if [ $? -ne 0 ]; then
        # There was a failure, just account for it.
        echo "Build failure, please check the output above. Exit code was: $?"
        return 1
    fi
popd
