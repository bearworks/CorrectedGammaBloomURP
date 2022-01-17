Shader "SkyGradient"
{
Properties {
    [HDR]_Tint ("Tint Color", Color) = (1, 1, 1, 1)

	[HDR]_SunColor("Sun Color", Color) = (1, 1, 1, 1)

	_SunSize("Sun Size", Range(0,1)) = 0.04
	_SunSizeConvergence("Sun Size Convergence", Range(1,10)) = 5
}

SubShader {
    Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
	LOD 300
			
    Cull Off ZWrite Off

    Pass {

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0

		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "AutoLight.cginc"

		half3 XLinearToGammaSpace(half3 c)
		{
			#ifdef UNITY_COLORSPACE_GAMMA 
				return LinearToGammaSpace(c.rgb);
			#else
				return c.rgb;
			#endif
		}

        half4 _Tint;
		float4 _SunColor;

		#define MIE_G (-0.990)
		#define MIE_G2 0.9801

		uniform half _SunSize;
		uniform half _SunSizeConvergence;

		// Calculates the Mie phase function
		half getMiePhase(half eyeCos, half eyeCos2)
		{
			half temp = 1.0 + MIE_G2 - 2.0 * MIE_G * eyeCos;
			temp = pow(temp, pow(_SunSize, 0.65) * 10);
			temp = max(temp, 1.0e-4); // prevent division by zero, esp. in half precision
			temp = 1.5 * ((1.0 - MIE_G2) / (2.0 + MIE_G2)) * (1.0 + eyeCos2) / temp;
#if defined(UNITY_COLORSPACE_GAMMA) && SKYBOX_COLOR_IN_TARGET_COLOR_SPACE
			temp = pow(temp, .454545);
#endif
			return temp;
		}

        struct appdata_t {
            float4 vertex : POSITION;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f {
            float4 vertex : SV_POSITION;
            float3 texcoord : TEXCOORD0;
			float3 Ds : TEXCOORD1;
            UNITY_VERTEX_OUTPUT_STEREO
        };

        v2f vert (appdata_t v)
        {
            v2f o;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

			float3 Ds = _WorldSpaceLightPos0.xyz;
			o.Ds = Ds;

            float3 rotated = v.vertex;
            o.vertex = UnityObjectToClipPos(rotated);
            o.texcoord = v.vertex.xyz;
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            float3 eyeVec = normalize(mul(unity_ObjectToWorld, i.texcoord));

			float cosine = clamp(dot(eyeVec, i.Ds), 0.0, 1.0);
	
			half focusedEyeCos = pow(cosine, _SunSizeConvergence);
			float3 color = getMiePhase(-focusedEyeCos, focusedEyeCos * focusedEyeCos) * _SunColor.rgb * _LightColor0.xyz * 0.25;

            half3 c = 0.2;

            c = lerp(1, c * _Tint.rgb, smoothstep(-1, 0.5, eyeVec.y));

			c.rgb = XLinearToGammaSpace(c.rgb + color);

            return half4(c, 1);
        }
        ENDCG
    }
}



Fallback Off

}
