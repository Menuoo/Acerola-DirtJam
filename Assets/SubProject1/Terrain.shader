Shader "Custom/Terrain"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_LowSlopeColor ("Low Slope Color", Color) = (1, 1, 1, 1)
		_HighSlopeColor ("High Slope Color", Color) = (1, 1, 1, 1)
		_AmbianceColor ("Ambiance Color", Color) = (0, 0, 0, 0)

		_Seed ("Seed", int) = 0
		_Offset ("Offset", Vector) = (0, 0, 0, 0)
		_Height ("Height", Float) = 1
		_Zoom ("Zoom", Float) = 1
		_Octaves ("Octaves", Range(1, 32)) = 1
		_Amplitude ("Amplitude", Range(0, 2)) = 0.5
		_AmplitudeDecay ("Amplitude Decay", Range(0,1)) = 0.5
		_Lacunarity ("Lacunarity", Float) = 2
		_FreqLowBound ("Frequency Variance Lower Bound", Float) = 0
		_FreqHighBound ("Frequency Variance Higher Bound", Float) = 0 
		_GradientRotation ("Gradient Rotation", Float) = 0

		_SlopeDamping ("Slope Damping", Range(0, 1)) = 0
		_SlopeThresholdLow ("Lower Slope Threshold", Range(0, 1)) = 0
		_SlopeThresholdHi ("Higher Slope Threshold", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 position : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float4 _LightDir;
			float4 _LowSlopeColor, _HighSlopeColor, _AmbianceColor, _Offset;
			float _Seed, _Height, _Zoom, _Octaves, _Amplitude, _AmplitudeDecay, _Lacunarity;
			float _FreqHighBound, _FreqLowBound, _GradientRotation;
			float _SlopeDamping, _SlopeThresholdLow, _SlopeThresholdHi;

			#define PI 3.141592653589793238462


            // UE4's PseudoRandom function
            float pseudo(float2 v) {
			    v = frac(v/128) * 128 + float2(-64.340622, -72.465622);
			    return frac(dot(v.xyx * v.xyy, float3(20.390625, 60.703125, 2.4281209)));
		    }

		    // Takes our xz positions and turns them into a random number between 0 and 1 using the above pseudo random function
		    float HashPosition(float2 pos) {
			    return pseudo(pos * float2(1 + _Seed, 1 + _Seed + 4));
		    }

            // Generates a random gradient vector for the perlin noise lattice points, watch my perlin noise video for a more in depth explanation
			float2 RandVector(float seed) {
				float theta = seed * 360 * 2 - 360;
				theta += _GradientRotation;
				theta = theta * PI / 180.0;
				return normalize(float2(cos(theta), sin(theta)));
			}

			// Normal smoothstep is cubic -- to avoid discontinuities in the gradient, we use a quintic interpolation instead as explained in my perlin noise video
			float2 quinticInterpolation(float2 t) {
				return t * t * t * (t * (t * float2(6, 6) - float2(15, 15)) + float2(10, 10));
			}

			// Derivative of above function
			float2 quinticDerivative(float2 t) {
				return float2(30, 30) * t * t * (t * (t - float2(2, 2)) + float2(1, 1));
			}

            // Perlin Noise fucntion
            float3 PerlinNoise2D(float2 pos) {
			    float2 latticeMin = floor(pos);
			    float2 latticeMax = ceil(pos);

			    float2 remainder = frac(pos);

			    // Lattice Corners
			    float2 c00 = latticeMin;
			    float2 c10 = float2(latticeMax.x, latticeMin.y);
			    float2 c01 = float2(latticeMin.x, latticeMax.y);
			    float2 c11 = latticeMax;

			    // Gradient Vectors assigned to each corner
			    float2 g00 = RandVector(HashPosition(c00));
			    float2 g10 = RandVector(HashPosition(c10));
			    float2 g01 = RandVector(HashPosition(c01));
			    float2 g11 = RandVector(HashPosition(c11));

			    // Directions to position from lattice corners
			    float2 p0 = remainder;
			    float2 p1 = p0 - float2(1.0, 1.0);

			    float2 p00 = p0;
			    float2 p10 = float2(p1.x, p0.y);
			    float2 p01 = float2(p0.x, p1.y);
			    float2 p11 = p1;
			
			    float2 u = quinticInterpolation(remainder);
			    float2 du = quinticDerivative(remainder);

			    float a = dot(g00, p00);
			    float b = dot(g10, p10);
			    float c = dot(g01, p01);
			    float d = dot(g11, p11);

			    // Expanded interpolation freaks of nature from https://iquilezles.org/articles/gradientnoise/
			    float noise = a + u.x * (b - a) + u.y * (c - a) + u.x * u.y * (a - b - c + d);

			    float2 gradient = g00 + u.x * (g10 - g00) + u.y * (g01 - g00) + u.x * u.y * (g00 - g10 - g01 + g11) + du * (u.yx * (a - b - c + d) + float2(b, c) - a);
			    return float3(noise, gradient);
		    }

			float3 fbm(float2 pos)
			{
				float lacunarity = _Lacunarity;
				float amplitude = _Amplitude;

				float height = 0;
				float2 grad = 0;

				float2x2 m = float2x2(1, 0,
									  0, 1);

			
				for (int i = 0; i < _Octaves; i++)
				{
					float3 noise = PerlinNoise2D(pos);	
					height += noise.x * amplitude;

					grad += mul(m, noise.yz * amplitude);

					float frequencyVariance = lerp(_FreqLowBound, _FreqHighBound, HashPosition(float2(i * 422, _Seed)));

					amplitude *= _AmplitudeDecay;
					pos *= (lacunarity + frequencyVariance);
					m = mul(m, (lacunarity + frequencyVariance));
				}

				return float3(height, grad);
			}



            v2f vert (appdata v)
            {
				float3 noisePos = (v.vertex + _Offset) / _Zoom;
				float3 noise = fbm(noisePos.xz); 

                v.vertex.y += _Height * noise.x + _Height - _Offset.y;


                v2f i;
				i.position = v.vertex;
                i.vertex = UnityObjectToClipPos(v.vertex);

                return i;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float3 noisePos = (i.position + _Offset) / _Zoom;
				float3 noise = _Height * fbm(noisePos.xz);

				
				float3 slopeNormal = normalize(float3(-noise.y, 1, -noise.z) * float3(_SlopeDamping, 1, _SlopeDamping));

				float blendFactor = smoothstep(_SlopeThresholdLow, _SlopeThresholdHi, 1 - slopeNormal.y);

				float4 albedo = lerp(_LowSlopeColor, _HighSlopeColor, blendFactor);
				float4 ambient = _AmbianceColor;


				float3 normal = normalize(float3(-noise.y, 1, -noise.z));
				float ndotl = saturate(dot(-_LightDir.xyz, normal));

                fixed4 diffuse = albedo * ndotl;
				fixed4 amb = albedo * ambient;

                return saturate(diffuse + amb);
            }

            ENDCG
        }
    }
}
