#ifndef RAYTRACING_GLSL
#define RAYTRACING_GLSL

#ifdef RAYTRACING

/*

// From globaldescriptorset.glsl:

layout(set = 0, binding = 4) uniform accelerationStructureEXT uRaytracingTopLevelAccelerationStructure; // Top level acceleration structure

layout(set = 0, std140, binding = 5) uniform RaytracingData { 
  // Everything here is just a buffer reference / pointer to the actual data in the buffers
  RaytracingGeometryInstanceOffsets geometryInstanceOffsets;
  RaytracingGeometryItems geometryItems;
  RaytracingMeshStaticVertices meshStaticVertices;
  RaytracingMeshDynamicVertices meshDynamicVertices;
  RaytracingMeshIndices meshIndices;  
  RaytracingParticleVertices particleVertices;
  RaytracingPlanetBufRefDataArray planetBufRefDataArray;
  RaytracingPlanetVerticesArray planetVerticesArray;
} uRaytracingData;

layout(set = 0, binding = 6) uniform sampler2D u2DTextures[]; // Bindless freely random indexable texture array
*/

vec4 raytracingTextureFetch(const in Material material, const in int textureIndex, const in vec4 defaultValue, const bool sRGB, const in vec2 texCoords[2]){
  int textureID = material.textures[textureIndex];
  if(textureID >= 0){
    int texCoordIndex = int((textureID >> 16) & 0xf); 
    mat3x2 m = material.textureTransforms[textureIndex];
    return textureLod(u2DTextures[nonuniformEXT(((textureID & 0x3fff) << 1) | (int(sRGB) & 1))], (m * vec3(texCoords[texCoordIndex], 1.0)).xy, 0);
  }else{
    return defaultValue;
  } 
}

// Fast hard shadow raytracing just for opaque triangles, without alpha cut-off and alpha blending testing, and not with the support for
// custom intersection shaders of custom shapes, and so on. So this is really for the most simple and fast hard shadow raytracing.
float getRaytracedFastHardShadow(vec3 position, vec3 direction, float minDistance, float maxDistance){
  const uint flags = gl_RayFlagsTerminateOnFirstHitEXT | gl_RayFlagsCullNoOpaqueEXT;
  rayQueryEXT rayQuery;
  rayQueryInitializeEXT(rayQuery, uRaytracingTopLevelAccelerationStructure, flags, 0xff, position, minDistance, direction, maxDistance);
  rayQueryProceedEXT(rayQuery); // No loop needed here, since we are only interested in the first hit (terminate on first hit flag is set above)
  float result = (rayQueryGetIntersectionTypeEXT(rayQuery, true) == gl_RayQueryCandidateIntersectionTriangleEXT) ? 0.0 : 1.0;
  rayQueryTerminateEXT(rayQuery);
  return result;
}                 

// Full hard shadow raytracing with alpha cut-off and alpha blending support and so on
float getRaytracedHardShadow(vec3 position, vec3 direction, float minDistance, float maxDistance){

  float result = 1.0;

  const uint flags = 0 | 
                     //gl_RayFlagsCullFrontFacingTrianglesEXT |
                     //gl_RayFlagsTerminateOnFirstHitEXT | 
                     //gl_RayFlagsOpaqueEXT |
                     //gl_RayFlagsSkipClosestHitShaderEXT |
                     0;

  rayQueryEXT rayQuery;
  rayQueryInitializeEXT(rayQuery, uRaytracingTopLevelAccelerationStructure, flags, 0xff, position, minDistance, direction, maxDistance);

  bool done = false;
  while((!done) && rayQueryProceedEXT(rayQuery)){

    uint intersectionType = rayQueryGetIntersectionTypeEXT(rayQuery, false);
    
    switch(intersectionType){
    
      case gl_RayQueryCandidateIntersectionTriangleEXT:{
    
        bool opaqueHit = (rayQueryGetRayFlagsEXT(rayQuery) & gl_RayFlagsOpaqueEXT) != 0;
    
        if(opaqueHit){

          // Shortcut for opaque triangles, no need to check material alpha cut-off or alpha blending here
    
          rayQueryConfirmIntersectionEXT(rayQuery);
          result = 0.0;
          done = true;

        }else{

          // With possible transparent triangles we need to check the material alpha cut-off and alpha blending

          int instanceID = rayQueryGetIntersectionInstanceIdEXT(rayQuery, false);
          
          int geometryID = rayQueryGetIntersectionGeometryIndexEXT(rayQuery, false);
          
          uint geometryInstanceOffset = uRaytracingData.geometryInstanceOffsets.geometryInstanceOffsets[instanceID];
          
          RaytracingGeometryItem geometryItem = uRaytracingData.geometryItems.geometryItems[geometryInstanceOffset + geometryID];

          switch(geometryItem.objectType){

            case 0u:{

              // Mesh object type
    
              Material material = uMaterials.materials[geometryItem.materialIndex]; // <= buffer reference, so practically a pointer inside the shader here

              // Check if alpha cut-off or alpha blending is used
              if((material.alphaCutOffFlagsTex0Tex1.y & ((1u << 4u) | (1u << 5u))) != 0u){ 

                int primitiveID = rayQueryGetIntersectionPrimitiveIndexEXT(rayQuery, false);

                vec3 barycentrics = vec3(0.0, rayQueryGetIntersectionBarycentricsEXT(rayQuery, false));

                barycentrics.x = 1.0 - (barycentrics.y + barycentrics.z); // Calculate the missing barycentric coordinate
    
                uint indexOffset = geometryItem.indexOffset + (primitiveID * 3u);
                
                uvec3 indices = uvec3(
                  uRaytracingData.meshIndices.meshIndices[indexOffset + 0u],
                  uRaytracingData.meshIndices.meshIndices[indexOffset + 1u],
                  uRaytracingData.meshIndices.meshIndices[indexOffset + 2u]
                );

                vec4 vertexTexCoordsArray[3] = vec4[3](
                  uRaytracingData.meshStaticVertices.meshStaticVertices[indices.x].texCoords,
                  uRaytracingData.meshStaticVertices.meshStaticVertices[indices.y].texCoords,
                  uRaytracingData.meshStaticVertices.meshStaticVertices[indices.z].texCoords
                );

                vec4 vertexColorArray[3] = vec4[3](
                  vec4(unpackHalf2x16(uRaytracingData.meshStaticVertices.meshStaticVertices[indices.x].color0MaterialID.x), unpackHalf2x16(uRaytracingData.meshStaticVertices.meshStaticVertices[indices.x].color0MaterialID.y)),
                  vec4(unpackHalf2x16(uRaytracingData.meshStaticVertices.meshStaticVertices[indices.y].color0MaterialID.x), unpackHalf2x16(uRaytracingData.meshStaticVertices.meshStaticVertices[indices.y].color0MaterialID.y)),
                  vec4(unpackHalf2x16(uRaytracingData.meshStaticVertices.meshStaticVertices[indices.z].color0MaterialID.x), unpackHalf2x16(uRaytracingData.meshStaticVertices.meshStaticVertices[indices.z].color0MaterialID.y))                
                );

                vec4 vertexTexCoords = (barycentrics.x * vertexTexCoordsArray[0]) + (barycentrics.y * vertexTexCoordsArray[1]) + (barycentrics.z * vertexTexCoordsArray[2]);

                vec4 vertexColor = (barycentrics.x * vertexColorArray[0]) + (barycentrics.y * vertexColorArray[1]) + (barycentrics.z * vertexColorArray[2]);

                vec2 texCoords[2] = vec2[2]( vertexTexCoords.xy, vertexTexCoords.zw );

                if((material.alphaCutOffFlagsTex0Tex1.y & (1u << 4u)) != 0u){
                  // Mask / Alpha Test
                  float alpha = raytracingTextureFetch(material, 0, vec4(1.0), true, texCoords).w * material.baseColorFactor.w * vertexColor.w;
                  if(alpha >= uintBitsToFloat(material.alphaCutOffFlagsTex0Tex1.x)){
                    rayQueryConfirmIntersectionEXT(rayQuery);
                    result = 0.0;
                    done = true;
                  }              
                }else if((material.alphaCutOffFlagsTex0Tex1.y & (1u << 5u)) != 0u){
                  // Blend / Alpha Blend
                  float alpha = raytracingTextureFetch(material, 0, vec4(1.0), true, texCoords).w * material.baseColorFactor.w * vertexColor.w;
                  result *= (1.0 - alpha);
                }else{
                  // Opaque, but should not happen here, since we have already checked above for opaque hits
                  rayQueryConfirmIntersectionEXT(rayQuery);
                  result = 0.0;
                  done = true;
                }

              }else{
                  
                // Opaque
                rayQueryConfirmIntersectionEXT(rayQuery);
                result = 0.0;
                done = true;

              } 

              break;

            }

            case 1u:{
              
              // Particle object type, ignore for now, but TODO
              break;

            } 

            case 2u:{
              
              // Planet object type, consider as opaque for all cases for now, since the ground should be always opaque on the planets
 
              rayQueryConfirmIntersectionEXT(rayQuery);
              result = 0.0;
              done = true;

              break;

            }

            default:{
              break;
            }

          } 

        }

        break;
      }

      case gl_RayQueryCandidateIntersectionAABBEXT:{
        // Ignore for now
        //rayQueryGenerateIntersectionEXT(rayQuery, 0.0);
        break;
      }

      default:{
        break;
      }

    } 

  }

  // Terminate the ray query 
  rayQueryTerminateEXT(rayQuery);

  // Return the result
  return result;

}

#endif // RAYTRACING

#endif // RAYTRACING_GLSL