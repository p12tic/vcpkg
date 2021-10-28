vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO alicevision/AliceVision
    REF v2.4.0
    SHA512 bb6bc50738e0c64f5ca1527911eb1265262320a20929d9fef6b4a56f69c8d542daa8acc92f28ee40a0a5d493d4cfc6009a7d534b741c64c1ebfc3fa3ef850d56
    HEAD_REF develop
)



vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
        FEATURES
            alembic    ALICEVISION_USE_ALEMBIC 
            cctag      ALICEVISION_USE_CCTAG
            cuda       ALICEVISION_USE_CUDA
            hdr        ALICEVISION_BUILD_HDR 
            mvs        ALICEVISION_BUILD_MVS
            opencv     ALICEVISION_USE_OPENCV
            openmp     ALICEVISION_USE_OPENMP
            popsift    ALICEVISION_USE_POPSIFT
            sfm        ALICEVISION_BUILD_SFM
            software   ALICEVISION_BUILD_SOFTWARE
)

# find cuda if necessary
if("cuda" IN_LIST FEATURES)
    include(${CURRENT_INSTALLED_DIR}/share/cuda/vcpkg_find_cuda.cmake)
    vcpkg_find_cuda(OUT_CUDA_TOOLKIT_ROOT CUDA_TOOLKIT_ROOT)

    message(STATUS "CUDA_TOOLKIT_ROOT ${CUDA_TOOLKIT_ROOT}")
endif()

# remove some cmake modules to force using our configs
file(REMOVE_RECURSE ${SOURCE_PATH}/src/cmake/FindLemon.cmake
                    ${SOURCE_PATH}/src/cmake/FindFlann.cmake
                    ${SOURCE_PATH}/src/cmake/FindCoinUtils.cmake
                    ${SOURCE_PATH}/src/cmake/FindClp.cmake
                    ${SOURCE_PATH}/src/cmake/FindOsi.cmake)

vcpkg_cmake_configure(
    SOURCE_PATH  "${SOURCE_PATH}"
    OPTIONS -DALICEVISION_BUILD_DOC:BOOL=OFF 
            -DALICEVISION_USE_MESHSDFILTER:BOOL=OFF
            ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH share/aliceVision/cmake)

vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include ${CURRENT_PACKAGES_DIR}/debug/share)

# move the bin directory to tools
if ("software" IN_LIST FEATURES)
    set(ALICEVISION_TOOLS 
            aliceVision_cameraInit-2.0
            aliceVision_cameraLocalization-1.0
            aliceVision_computeStructureFromKnownPoses-1.0
            aliceVision_convertFloatDescriptorToUchar-1.0
            aliceVision_convertMesh-1.0
            aliceVision_convertRAW-1.0
            aliceVision_convertSfMFormat-2.0
            aliceVision_depthMapEstimation-2.0
            aliceVision_depthMapFiltering-2.0
            aliceVision_distortionCalibration-0.1
            aliceVision_exportAnimatedCamera-2.0
            aliceVision_exportCameraFrustums-1.0
            aliceVision_exportColoredPointCloud-1.0
            aliceVision_exportKeypoints-1.0
            aliceVision_exportMatches-1.0
            aliceVision_exportMatlab-1.0
            aliceVision_exportMeshlab-1.0
            aliceVision_exportMeshroomMaya-1.0
            aliceVision_exportMVE2-1.0
            aliceVision_exportMVSTexturing-1.0
            aliceVision_exportPMVS-1.0
            aliceVision_exportTracks-1.0
            aliceVision_featureExtraction-1.0
            aliceVision_featureMatching-2.0
            aliceVision_globalSfM-1.0
            aliceVision_imageMatching-1.0
            aliceVision_importKnownPoses-2.0
            aliceVision_incrementalSfM-2.1
            aliceVision_LdrToHdrCalibration-0.1
            aliceVision_LdrToHdrMerge-0.1
            aliceVision_LdrToHdrSampling-0.1
            aliceVision_meshDecimate-1.0
            aliceVision_meshDenoising-1.0
            aliceVision_meshFiltering-4.0
            aliceVision_meshing-4.0
            aliceVision_meshMasking-1.0
            aliceVision_meshResampling-1.0
            aliceVision_panoramaCompositing-1.0
            aliceVision_panoramaEstimation-1.0
            aliceVision_panoramaInit-2.0
            aliceVision_panoramaMerging-1.0
            aliceVision_panoramaPrepareImages-0.1
            aliceVision_panoramaSeams-1.0
            aliceVision_panoramaWarping-1.0
            aliceVision_prepareDenseScene-2.0
            aliceVision_rigCalibration-1.0
            aliceVision_rigLocalization-1.0
            aliceVision_texturing-3.0
            aliceVision_utils_fisheyeProjection-1.0
            aliceVision_utils_frustumFiltering-1.0
            aliceVision_utils_generateSampleScene-1.0
            aliceVision_utils_hardwareResources-1.0
            aliceVision_utils_imageProcessing-2.0
            aliceVision_utils_importMiddlebury-1.0
            aliceVision_utils_keyframeSelection-2.0
            aliceVision_utils_lightingEstimation-1.0
            aliceVision_utils_mergeMeshes-1.0
            aliceVision_utils_qualityEvaluation-1.0
            aliceVision_utils_rigTransform-1.0
            aliceVision_utils_sfmAlignment-1.0
            aliceVision_utils_sfmColorHarmonize-1.0
            aliceVision_utils_sfmDistances-1.0
            aliceVision_utils_sfmLocalization-1.0
            aliceVision_utils_sfmTransfer-1.0
            aliceVision_utils_sfmTransform-1.0
            aliceVision_utils_split360Images-1.0
            aliceVision_utils_voctreeCreation-1.0
            aliceVision_utils_voctreeQueryUtility-1.0
            aliceVision_utils_voctreeStatistics-1.0)
    vcpkg_copy_tools(TOOL_NAMES ${ALICEVISION_TOOLS} AUTO_CLEAN)
endif()

# todo see where to install other license and the camera databse
file(INSTALL ${SOURCE_PATH}/COPYING.md DESTINATION ${CURRENT_PACKAGES_DIR}/share/alicevision RENAME copyright)