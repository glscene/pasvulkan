#ifndef ATMOSPHERE_COMMON_GLSL
#define ATMOSPHERE_COMMON_GLSL

// Based on: https://github.com/sebh/UnrealEngineSkyAtmosphere

#define ILLUMINANCE_IS_ONE

#define TRANSMITTANCE_TEXTURE_WIDTH 256
#define TRANSMITTANCE_TEXTURE_HEIGHT 64
#define SCATTERING_TEXTURE_R_SIZE 32
#define SCATTERING_TEXTURE_MU_SIZE 128
#define SCATTERING_TEXTURE_MU_S_SIZE 32
#define SCATTERING_TEXTURE_NU_SIZE 8
#define SCATTERING_TEXTURE_WIDTH (SCATTERING_TEXTURE_NU_SIZE * SCATTERING_TEXTURE_MU_S_SIZE)
#define SCATTERING_TEXTURE_HEIGHT SCATTERING_TEXTURE_MU_SIZE
#define SCATTERING_TEXTURE_DEPTH SCATTERING_TEXTURE_R_SIZE
#define IRRADIANCE_TEXTURE_WIDTH 64
#define IRRADIANCE_TEXTURE_HEIGHT 16
#define MultiScatteringLUTRes 32

#define AP_SLICE_COUNT_INT 32
#define AP_SLICE_COUNT 32.0
#define AP_KM_PER_SLICE 4.0

const float PI = 3.1415926535897932384626433832795;

struct DensityProfileLayer {
  float Width;
  float ExpTerm;
  float ExpScale;
  float LinearTerm;
  float ConstantTerm;
  float Unused0;
  float Unused1;
  float Unused2;
};

struct DensityProfile {
  DensityProfileLayer Layers[2];
};

struct InAtmosphereParameters {
  DensityProfile RayleighDensity;
  DensityProfile MieDensity;
  DensityProfile AbsorptionDensity;
  vec4 Center;
  vec4 SolarIrradiance;
  vec4 RayleighScattering;
  vec4 MieScattering;
  vec4 MieExtinction;
  vec4 AbsorptionExtinction;
  vec4 GroundAlbedo;
  float MiePhaseFunctionG;
  float SunAngularRadius;
  float BottomRadius;
  float TopRadius;
  float MuSMin;
};

struct AtmosphereParameters {
  float BottomRadius;
	float TopRadius;
	float RayleighDensityExpScale;
	vec3 RayleighScattering;

	float MieDensityExpScale;
	vec3 MieScattering;
	vec3 MieExtinction;
	vec3 MieAbsorption;
	float MiePhaseG;

	float AbsorptionDensity0LayerWidth;
	float AbsorptionDensity0ConstantTerm;
	float AbsorptionDensity0LinearTerm;
	float AbsorptionDensity1ConstantTerm;
	float AbsorptionDensity1LinearTerm;
	vec3 AbsorptionExtinction;

	vec3 GroundAlbedo;
};

AtmosphereParameters getAtmosphereParameters(const in InAtmosphereParameters inAtmosphereParameters){
  AtmosphereParameters atmosphereParameters;
  atmosphereParameters.BottomRadius = inAtmosphereParameters.BottomRadius;
  atmosphereParameters.TopRadius = inAtmosphereParameters.TopRadius;
  atmosphereParameters.RayleighDensityExpScale = inAtmosphereParameters.RayleighDensity.Layers[0].ExpScale;
  atmosphereParameters.RayleighScattering = inAtmosphereParameters.RayleighScattering.xyz;

  atmosphereParameters.MieDensityExpScale = inAtmosphereParameters.MieDensity.Layers[0].ExpScale;
  atmosphereParameters.MieScattering = inAtmosphereParameters.MieScattering.xyz;
  atmosphereParameters.MieExtinction = inAtmosphereParameters.MieExtinction.xyz;
  atmosphereParameters.MieAbsorption = inAtmosphereParameters.AbsorptionExtinction.xyz;
  atmosphereParameters.MiePhaseG = inAtmosphereParameters.MiePhaseFunctionG;

  atmosphereParameters.AbsorptionDensity0LayerWidth = inAtmosphereParameters.AbsorptionDensity.Layers[0].Width;
  atmosphereParameters.AbsorptionDensity0ConstantTerm = inAtmosphereParameters.AbsorptionDensity.Layers[0].ConstantTerm;
  atmosphereParameters.AbsorptionDensity0LinearTerm = inAtmosphereParameters.AbsorptionDensity.Layers[0].LinearTerm;
  atmosphereParameters.AbsorptionDensity1ConstantTerm = inAtmosphereParameters.AbsorptionDensity.Layers[1].ConstantTerm;
  atmosphereParameters.AbsorptionDensity1LinearTerm = inAtmosphereParameters.AbsorptionDensity.Layers[1].LinearTerm;
  atmosphereParameters.AbsorptionExtinction = inAtmosphereParameters.AbsorptionExtinction.xyz;

  atmosphereParameters.GroundAlbedo = inAtmosphereParameters.GroundAlbedo.xyz;

  return atmosphereParameters;
}

struct SingleScatteringResult {
	vec3 L;						// Scattered light (luminance)
	vec3 OpticalDepth;			// Optical depth (1/m)
	vec3 Transmittance;			// Transmittance in [0,1] (unitless)
	vec3 MultiScatAs1;
	vec3 NewMultiScatStep0Out;
	vec3 NewMultiScatStep1Out;
};

vec2 gResolution;

mat4 gSkyInvViewProjMat;

vec2 RayMarchMinMaxSPP = vec2(4.0, 14.0);

#define PLANET_RADIUS_OFFSET 0.01f

struct Ray{
	vec3 o;
	vec3 d;
};

Ray createRay(in vec3 p, in vec3 d){
	Ray r;
	r.o = p;
	r.d = d;
	return r;
}

float fromUnitToSubUvs(float u, float resolution){ return ((u + 0.5) / resolution) * (resolution / (resolution + 1.0)); }
float fromSubUvsToUnit(float u, float resolution){ return ((u - 0.5) / resolution) * (resolution / (resolution - 1.0)); }

void UvToLutTransmittanceParams(AtmosphereParameters Atmosphere, out float viewHeight, out float viewZenithCosAngle, in vec2 uv){
	//uv = vec2(fromSubUvsToUnit(uv.x, TRANSMITTANCE_TEXTURE_WIDTH), fromSubUvsToUnit(uv.y, TRANSMITTANCE_TEXTURE_HEIGHT)); // No real impact so off
	float x_mu = uv.x;
	float x_r = uv.y;

	float H = sqrt((Atmosphere.TopRadius * Atmosphere.TopRadius) - (Atmosphere.BottomRadius * Atmosphere.BottomRadius));
	float rho = H * x_r;
	viewHeight = sqrt((rho * rho) + (Atmosphere.BottomRadius * Atmosphere.BottomRadius));

	float d_min = Atmosphere.TopRadius - viewHeight;
	float d_max = rho + H;
	float d = d_min + x_mu * (d_max - d_min);
	viewZenithCosAngle = (d == 0.0) ? 1.0 : (((H * H) - (rho * rho)) - (d * d)) / (2.0 * viewHeight * d);
	viewZenithCosAngle = clamp(viewZenithCosAngle, -1.0, 1.0);
}

#define NONLINEARSKYVIEWLUT 1
void UvToSkyViewLutParams(AtmosphereParameters Atmosphere, out float viewZenithCosAngle, out float lightViewCosAngle, in float viewHeight, in vec2 uv){
	// Constrain uvs to valid sub texel range (avoid zenith derivative issue making LUT usage visible)
	uv = vec2(fromSubUvsToUnit(uv.x, 192.0), fromSubUvsToUnit(uv.y, 108.0));

	float Vhorizon = sqrt((viewHeight * viewHeight) - (Atmosphere.BottomRadius * Atmosphere.BottomRadius));
	float CosBeta = Vhorizon / viewHeight;				// GroundToHorizonCos
	float Beta = acos(CosBeta);
	float ZenithHorizonAngle = PI - Beta;

	if(uv.y < 0.5){
		float coord = 2.0 * uv.y;
		coord = 1.0 - coord;
#if NONLINEARSKYVIEWLUT
		coord *= coord;
#endif
		coord = 1.0 - coord;
		viewZenithCosAngle = cos(ZenithHorizonAngle * coord);
	}else{
		float coord = fma(uv.y, 2.0, -1.0);
#if NONLINEARSKYVIEWLUT
		coord *= coord;
#endif
		viewZenithCosAngle = cos(ZenithHorizonAngle + Beta * coord);
	}

	float coord = uv.x;
	coord *= coord;
	lightViewCosAngle = -fma(coord, 2.0, -1.0);
}

void SkyViewLutParamsToUv(AtmosphereParameters Atmosphere, in bool IntersectGround, in float viewZenithCosAngle, in float lightViewCosAngle, in float viewHeight, out vec2 uv){
	float Vhorizon = sqrt((viewHeight * viewHeight) - (Atmosphere.BottomRadius * Atmosphere.BottomRadius));
	float CosBeta = Vhorizon / viewHeight;				// GroundToHorizonCos
	float Beta = acos(CosBeta);
	float ZenithHorizonAngle = PI - Beta;

	if(!IntersectGround){
		float coord = acos(viewZenithCosAngle) / ZenithHorizonAngle;
		coord = 1.0 - coord;
#if NONLINEARSKYVIEWLUT
		coord = sqrt(coord);
#endif
		coord = 1.0 - coord;
		uv.y = coord * 0.5;
	}else{
		float coord = (acos(viewZenithCosAngle) - ZenithHorizonAngle) / Beta;
#if NONLINEARSKYVIEWLUT
		coord = sqrt(coord);
#endif
		uv.y = fma(coord, 0.5, 0.5);
	}

	{
		float coord = fma(lightViewCosAngle, -0.5, 0.5);
		coord = sqrt(coord);
		uv.x = coord;
	}

	// Constrain uvs to valid sub texel range (avoid zenith derivative issue making LUT usage visible)
	uv = vec2(fromUnitToSubUvs(uv.x, 192.0), fromUnitToSubUvs(uv.y, 108.0));
}

float raySphereIntersectNearest(vec3 r0, vec3 rd, vec3 s0, float sR){
  float a = dot(rd, rd);
	vec3 s0_r0 = r0 - s0;
	float b = 2.0 * dot(rd, s0_r0);
	float c = dot(s0_r0, s0_r0) - (sR * sR);
	float delta = (b * b) - (4.0 * a * c);
	if((delta < 0.0) || (a == 0.0)){
		return -1.0;
	}else{
    vec2 sol01 = (vec2(-b) + (vec2(sqrt(delta)) * vec2(-1.0, 1.0))) / vec2(2.0 * a);
    if(all(lessThan(sol01, vec2(0.0)))){
      return -1.0;
    }else if(sol01.x < 0.0){
      return max(0.0, sol01.y);
    }else if(sol01.y < 0.0){
      return max(0.0, sol01.x);
    }else{
      return max(0.0, min(sol01.x, sol01.y));
    }
  }
}

void LutTransmittanceParamsToUv(const in AtmosphereParameters Atmosphere, in float viewHeight, in float viewZenithCosAngle, out vec2 uv){
	
  float H = sqrt(max(0.0, Atmosphere.TopRadius * Atmosphere.TopRadius - Atmosphere.BottomRadius * Atmosphere.BottomRadius));
	float rho = sqrt(max(0.0, viewHeight * viewHeight - Atmosphere.BottomRadius * Atmosphere.BottomRadius));

	float discriminant = viewHeight * viewHeight * (viewZenithCosAngle * viewZenithCosAngle - 1.0) + Atmosphere.TopRadius * Atmosphere.TopRadius;
	float d = max(0.0, (-viewHeight * viewZenithCosAngle + sqrt(discriminant))); // Distance to atmosphere boundary

	float d_min = Atmosphere.TopRadius - viewHeight;
	float d_max = rho + H;
	float x_mu = (d - d_min) / (d_max - d_min);
	float x_r = rho / H;

	uv = vec2(x_mu, x_r);
	//uv = vec2(fromUnitToSubUvs(uv.x, TRANSMITTANCE_TEXTURE_WIDTH), fromUnitToSubUvs(uv.y, TRANSMITTANCE_TEXTURE_HEIGHT)); // No real impact so off
}

float RayleighPhase(float cosTheta){
	float factor = 3.0 / (16.0 * PI);
	return factor * (1.0 + (cosTheta * cosTheta));
}

float CornetteShanksMiePhaseFunction(float g, float cosTheta){
	float k = ((3.0 / (8.0 * PI)) * (1.0 - (g * g))) / (2.0 + (g * g));
	return (k * (1.0 + (cosTheta * cosTheta))) / pow((1.0 + (g * g)) - (2.0 * g * -cosTheta), 1.5);
}

float hgPhase(float g, float cosTheta){
#ifdef USE_CornetteShanks
	return CornetteShanksMiePhaseFunction(g, cosTheta);
#else
	// Reference implementation (i.e. not schlick approximation). 
	// See http://www.pbr-book.org/3ed-2018/Volume_Scattering/Phase_Functions.html
	float numer = 1.0 - (g * g);
	float denom = 1.0 + (g * g) + (2.0 * g * cosTheta);
	return numer / (4.0 * PI * denom * sqrt(denom));
#endif
}

float getAlbedo(float scattering, float extinction){
	return scattering / max(0.001, extinction);
}

vec3 getAlbedo(vec3 scattering, vec3 extinction){
	return scattering / max(vec3(0.001), extinction);
}

struct MediumSampleRGB {
  vec3 scattering;
	vec3 absorption;
	vec3 extinction;

	vec3 scatteringMie;
	vec3 absorptionMie;
	vec3 extinctionMie;

	vec3 scatteringRay;
	vec3 absorptionRay;
	vec3 extinctionRay;

	vec3 scatteringOzo;
	vec3 absorptionOzo;
	vec3 extinctionOzo;

	vec3 albedo;
};

MediumSampleRGB sampleMediumRGB(in vec3 WorldPos, in AtmosphereParameters Atmosphere){

	const float viewHeight = length(WorldPos) - Atmosphere.BottomRadius;

	const float densityMie = exp(Atmosphere.MieDensityExpScale * viewHeight);
	const float densityRay = exp(Atmosphere.RayleighDensityExpScale * viewHeight);
	const float densityOzo = clamp(viewHeight < Atmosphere.AbsorptionDensity0LayerWidth ?
		Atmosphere.AbsorptionDensity0LinearTerm * viewHeight + Atmosphere.AbsorptionDensity0ConstantTerm :
		Atmosphere.AbsorptionDensity1LinearTerm * viewHeight + Atmosphere.AbsorptionDensity1ConstantTerm, 
    0.0, 1.0);

	MediumSampleRGB s;

	s.scatteringMie = densityMie * Atmosphere.MieScattering;
	s.absorptionMie = densityMie * Atmosphere.MieAbsorption;
	s.extinctionMie = densityMie * Atmosphere.MieExtinction;

	s.scatteringRay = densityRay * Atmosphere.RayleighScattering;
	s.absorptionRay = vec3(0.0);
	s.extinctionRay = s.scatteringRay + s.absorptionRay;

	s.scatteringOzo = vec3(0.0);
	s.absorptionOzo = densityOzo * Atmosphere.AbsorptionExtinction;
	s.extinctionOzo = s.scatteringOzo + s.absorptionOzo;

	s.scattering = s.scatteringMie + s.scatteringRay + s.scatteringOzo;
	s.absorption = s.absorptionMie + s.absorptionRay + s.absorptionOzo;
	s.extinction = s.extinctionMie + s.extinctionRay + s.extinctionOzo;
	s.albedo = getAlbedo(s.scattering, s.extinction);

	return s;
}

vec3 GetMultipleScattering(const in sampler2DArray MultiScatTexture, int viewIndex, AtmosphereParameters Atmosphere, vec3 scattering, vec3 extinction, vec3 worlPos, float viewZenithCosAngle){
	vec2 uv = clamp(vec2(fma(viewZenithCosAngle, 0.5, 0.5), (length(worlPos) - Atmosphere.BottomRadius) / (Atmosphere.TopRadius - Atmosphere.BottomRadius)), vec2(0.0), vec2(1.0));
	uv = vec2(fromUnitToSubUvs(uv.x, MultiScatteringLUTRes), fromUnitToSubUvs(uv.y, MultiScatteringLUTRes));
	vec3 multiScatteredLuminance = textureLod(MultiScatTexture, vec3(uv, float(viewIndex)), 0).xyz;
	return multiScatteredLuminance;
}

float getShadow(in AtmosphereParameters Atmosphere, vec3 P){
  // TODO
	return 1.0;
}

SingleScatteringResult IntegrateScatteredLuminance(const in sampler2DArray TransmittanceLutTexture,
                                                   const in sampler2DArray MultiScatTexture, 
                                                   int viewIndex,
                                                   in vec2 pixPos, 
                                                   in vec3 WorldPos, 
                                                   in vec3 WorldDir, 
                                                   in vec3 SunDir, 
                                                   const in AtmosphereParameters Atmosphere,
                                                   in bool ground, 
                                                   in float SampleCountIni, 
                                                   in float DepthBufferValue, 
                                                   in bool VariableSampleCount,
                                                   in bool MieRayPhase, 
                                                   float tMaxMax){

  if(tMaxMax < 0.0){
    tMaxMax = 9000000.0;
  } 

  SingleScatteringResult result;

  vec3 ClipSpace = vec3(fma(vec2(pixPos) / vec2(gResolution), vec2(2.0), vec2(1.0)), 1.0);

  // Compute next intersection with atmosphere or ground 
  vec3 earthO = vec3(0.0);
  float tBottom = raySphereIntersectNearest(WorldPos, WorldDir, earthO, Atmosphere.BottomRadius);
	float tTop = raySphereIntersectNearest(WorldPos, WorldDir, earthO, Atmosphere.TopRadius);
	float tMax = 0.0;
	if(tBottom < 0.0){
		if (tTop < 0.0){
			tMax = 0.0; // No intersection with earth nor atmosphere: stop right away  
			return result;
		}else{
			tMax = tTop;
		}
	}else{
		if(tTop > 0.0){
			tMax = min(tTop, tBottom);
		}
	}  

	if(DepthBufferValue >= 0.0){
		ClipSpace.z = DepthBufferValue;
		if(ClipSpace.z < 1.0){
			vec4 DepthBufferWorldPos = gSkyInvViewProjMat * vec4(ClipSpace, 1.0);
			DepthBufferWorldPos /= DepthBufferWorldPos.w;

			float tDepth = length(DepthBufferWorldPos.xyz - (WorldPos + vec3(0.0, 0.0, -Atmosphere.BottomRadius))); // apply earth offset to go back to origin as top of earth mode. 
			if(tDepth < tMax){
				tMax = tDepth;
			}
		}
		/*
    if (VariableSampleCount && (ClipSpace.z == 1.0)){
		  return result;
    }*/
	}
	tMax = min(tMax, tMaxMax);

	// Sample count 
	float SampleCount = SampleCountIni;
	float SampleCountFloor = SampleCountIni;
	float tMaxFloor = tMax;
	if(VariableSampleCount){
		SampleCount = mix(RayMarchMinMaxSPP.x, RayMarchMinMaxSPP.y, clamp(tMax * 0.01, 0.0, 1.0));
		SampleCountFloor = floor(SampleCount);
		tMaxFloor = tMax * SampleCountFloor / SampleCount;	// rescale tMax to map to the last entire step segment.
	}
	float dt = tMax / SampleCount;

	// Phase functions
	const float uniformPhase = 1.0 / (4.0 * PI);
	const vec3 wi = SunDir;
	const vec3 wo = WorldDir;
	float cosTheta = dot(wi, wo);
	float MiePhaseValue = hgPhase(Atmosphere.MiePhaseG, -cosTheta);	// mnegate cosTheta because due to WorldDir being a "in" direction. 
	float RayleighPhaseValue = RayleighPhase(cosTheta);

#ifdef ILLUMINANCE_IS_ONE
	// When building the scattering factor, we assume light illuminance is 1 to compute a transfert function relative to identity illuminance of 1.
	// This make the scattering factor independent of the light. It is now only linked to the atmosphere properties.
	vec3 globalL = vec3(1.0);
#else
	vec3 globalL = gSunIlluminance;
#endif

	// Ray march the atmosphere to integrate optical depth
	vec3 L = vec3(0.0);
	vec3 throughput = vec3(1.0);
	vec3 OpticalDepth = vec3(0.0);
	float t = 0.0;
	float tPrev = 0.0;
	const float SampleSegmentT = 0.3;
	for (float s = 0.0; s < SampleCount; s += 1.0){
		if (VariableSampleCount){
			// More expenssive but artefact free
			float t0 = (s) / SampleCountFloor;
			float t1 = (s + 1.0) / SampleCountFloor;
			// Non linear distribution of sample within the range.
			t0 = t0 * t0;
			t1 = t1 * t1;
			// Make t0 and t1 world space distances.
			t0 = tMaxFloor * t0;
			if(t1 > 1.0){
				t1 = tMax;
		  //t1 = tMaxFloor;	// this reveal depth slices
			}else{
				t1 = tMaxFloor * t1;
			}
			//t = t0 + (t1 - t0) * (whangHashNoise(pixPos.x, pixPos.y, gFrameId * 1920 * 1080)); // With dithering required to hide some sampling artefact relying on TAA later? This may even allow volumetric shadow?
			t = t0 + ((t1 - t0) * SampleSegmentT);
			dt = t1 - t0;
		}else{
			//t = tMax * (s + SampleSegmentT) / SampleCount;
			// Exact difference, important for accuracy of multiple scattering
			float NewT = tMax * (s + SampleSegmentT) / SampleCount;
			dt = NewT - t;
			t = NewT;
		}
		vec3 P = WorldPos + t * WorldDir;

	  MediumSampleRGB medium = sampleMediumRGB(P, Atmosphere);
		const vec3 SampleOpticalDepth = medium.extinction * dt;
		const vec3 SampleTransmittance = exp(-SampleOpticalDepth);
		OpticalDepth += SampleOpticalDepth;

		float pHeight = length(P);
		const vec3 UpVector = P / pHeight;
		float SunZenithCosAngle = dot(SunDir, UpVector);
		vec2 uv;
		LutTransmittanceParamsToUv(Atmosphere, pHeight, SunZenithCosAngle, uv);
		vec3 TransmittanceToSun = textureLod(TransmittanceLutTexture, vec3(uv, float(viewIndex)), 0.0).xyz;

		vec3 PhaseTimesScattering;
		if(MieRayPhase){
			PhaseTimesScattering = medium.scatteringMie * MiePhaseValue + medium.scatteringRay * RayleighPhaseValue;
		}else{
			PhaseTimesScattering = medium.scattering * uniformPhase;
		}

		// Earth shadow 
		float tEarth = raySphereIntersectNearest(P, SunDir, earthO + PLANET_RADIUS_OFFSET * UpVector, Atmosphere.BottomRadius);
		float earthShadow = tEarth >= 0.0 ? 0.0 : 1.0;

		// Dual scattering for multi scattering 

		vec3 multiScatteredLuminance = vec3(0.0);
#if MULTISCATAPPROX_ENABLED
		multiScatteredLuminance = GetMultipleScattering(MultiScatTexture, viewIndex, Atmosphere, medium.scattering, medium.extinction, P, SunZenithCosAngle);
#endif

		float shadow = 1.0f;
#if SHADOWMAP_ENABLED
		// First evaluate opaque shadow
		shadow = getShadow(Atmosphere, P);
#endif

		vec3 S = globalL * (earthShadow * shadow * TransmittanceToSun * PhaseTimesScattering + multiScatteredLuminance * medium.scattering);

		// When using the power serie to accumulate all sattering order, serie r must be <1 for a serie to converge.
		// Under extreme coefficient, MultiScatAs1 can grow larger and thus result in broken visuals.
		// The way to fix that is to use a proper analytical integration as proposed in slide 28 of http://www.frostbite.com/2015/08/physically-based-unified-volumetric-rendering-in-frostbite/
		// However, it is possible to disable as it can also work using simple power serie sum unroll up to 5th order. The rest of the orders has a really low contribution.
#define MULTI_SCATTERING_POWER_SERIE 1

#if MULTI_SCATTERING_POWER_SERIE==0
		// 1 is the integration of luminance over the 4pi of a sphere, and assuming an isotropic phase function of 1.0/(4*PI)
		result.MultiScatAs1 += throughput * medium.scattering * 1 * dt;
#else
		vec3 MS = medium.scattering * 1;
		vec3 MSint = (MS - MS * SampleTransmittance) / medium.extinction;
		result.MultiScatAs1 += throughput * MSint;
#endif

		// Evaluate input to multi scattering 
		{
			vec3 newMS;

			newMS = earthShadow * TransmittanceToSun * medium.scattering * uniformPhase * 1;
			result.NewMultiScatStep0Out += throughput * (newMS - newMS * SampleTransmittance) / medium.extinction;
			//	result.NewMultiScatStep0Out += SampleTransmittance * throughput * newMS * dt;

			newMS = medium.scattering * uniformPhase * multiScatteredLuminance;
			result.NewMultiScatStep1Out += throughput * (newMS - newMS * SampleTransmittance) / medium.extinction;
			//	result.NewMultiScatStep1Out += SampleTransmittance * throughput * newMS * dt;
		}

#if 0
		L += throughput * S * dt;
		throughput *= SampleTransmittance;
#else
		// See slide 28 at http://www.frostbite.com/2015/08/physically-based-unified-volumetric-rendering-in-frostbite/ 
		vec3 Sint = (S - S * SampleTransmittance) / medium.extinction;	// integrate along the current step segment 
		L += throughput * Sint;														// accumulate and also take into account the transmittance from previous steps
		throughput *= SampleTransmittance;
#endif

		tPrev = t;

  }

	if(ground && (tMax == tBottom) && (tBottom > 0.0)){

		// Account for bounced light off the earth
		vec3 P = WorldPos + (tBottom * WorldDir);
		float pHeight = length(P);

		const vec3 UpVector = P / pHeight;
		float SunZenithCosAngle = dot(SunDir, UpVector);
		vec2 uv;
		LutTransmittanceParamsToUv(Atmosphere, pHeight, SunZenithCosAngle, uv);
		vec3 TransmittanceToSun = textureLod(TransmittanceLutTexture, vec3(uv, float(viewIndex)), 0.0).xyz;

		const float NdotL = clamp(dot(normalize(UpVector), normalize(SunDir)), 0.0, 1.0);
		L += globalL * TransmittanceToSun * throughput * NdotL * Atmosphere.GroundAlbedo / PI;

	}

	result.L = L;
	result.OpticalDepth = OpticalDepth;
	result.Transmittance = throughput;
  return result;

}

bool MoveToTopAtmosphere(inout vec3 WorldPos, in vec3 WorldDir, in float AtmosphereTopRadius){
	float viewHeight = length(WorldPos);
	if(viewHeight > AtmosphereTopRadius){
		float tTop = raySphereIntersectNearest(WorldPos, WorldDir, vec3(0.0), AtmosphereTopRadius);
		if(tTop >= 0.0){
			vec3 UpVector = WorldPos / viewHeight;
			vec3 UpOffset = UpVector * -PLANET_RADIUS_OFFSET;
			WorldPos = WorldPos + (WorldDir * tTop) + UpOffset;
		}else{
			// Ray is not intersecting the atmosphere
			return false;
		}
	}
	return true; // ok to start tracing
}


float AerialPerspectiveDepthToSlice(float depth){
	return depth * (1.0 / AP_KM_PER_SLICE);
}

float AerialPerspectiveSliceToDepth(float slice){
	return slice * AP_KM_PER_SLICE;
}


vec3 GetSunLuminance(vec3 WorldPos, vec3 WorldDir, vec3 sunDirection, float PlanetRadius){
	if (dot(WorldDir, sunDirection) > cos(0.5*0.505*3.14159 / 180.0)){
		float t = raySphereIntersectNearest(WorldPos, WorldDir, vec3(0.0), PlanetRadius);
		if(t < 0.0){ // no intersection
			const vec3 SunLuminance = vec3(1000000.0); // arbitrary. But fine, not use when comparing the models
			return SunLuminance;
		}
	}
	return vec3(0.0);
}

#endif