// Usage:

//  _lanczosEffect = Content.Load<Effect>("Lanczos");
//  _lanczosEffect.Parameters["inputWidth"].SetValue((float)_inputTexture.Width);
//  _lanczosEffect.Parameters["inputHeight"].SetValue((float)_inputTexture.Height);
//  _lanczosEffect.Parameters["inputPtX"].SetValue(1.0f / _inputTexture.Width);
//  _lanczosEffect.Parameters["inputPtY"].SetValue(1.0f / _inputTexture.Height);

// _spriteBatch.Begin(samplerState: SamplerState.PointClamp, effect: _lanczosEffect);
// _spriteBatch.Draw(
//     _inputTexture, 
//     new Rectangle(0, 0, _inputTexture.Width * 1.5, _inputTexture.Height * 1.5), 
//     Color.White);
//  _spriteBatch.End();

Texture2D Input : register(t0);
SamplerState TextureSampler : register(s0);

// Define the necessary constants
float inputWidth;
float inputHeight;
float inputPtX;
float inputPtY;

#define FIX(c) max(abs(c), 1e-5)
#define PI 3.14159265359
#define min4(a, b, c, d) min(min(a, b), min(c, d))
#define max4(a, b, c, d) max(max(a, b), max(c, d))

float3 weight3(float x)
{
    const float rcpRadius = 1.0f / 3.0f;
    float3 s = FIX(2.0 * PI * float3(x - 1.5, x - 0.5, x + 0.5));
	// Lanczos3. Note: we normalize outside this function, so no point in multiplying by radius.
    return /*radius **/sin(s) * sin(s * rcpRadius) * rcp(s * s);
}

struct PixelInput
{
    float4 Position : SV_Position0;
    float4 Color : COLOR0;
    float4 TexCoord : TEXCOORD0;
};

float4 SpritePixelShader(PixelInput p) : SV_TARGET
{
    float2 pos = float2(p.TexCoord.x * inputWidth, p.TexCoord.y * inputHeight);
    float2 inputPt = float2(inputPtX, inputPtY);

    uint i, j;

    float2 f = frac(pos.xy + 0.5f);
    float3 linetaps1 = weight3(0.5f - f.x * 0.5f);
    float3 linetaps2 = weight3(1.0f - f.x * 0.5f);
    float3 columntaps1 = weight3(0.5f - f.y * 0.5f);
    float3 columntaps2 = weight3(1.0f - f.y * 0.5f);

	// make sure all taps added together is exactly 1.0, otherwise some
	// (very small) distortion can occur
    float suml = dot(linetaps1, float3(1, 1, 1)) + dot(linetaps2, float3(1, 1, 1));
    float sumc = dot(columntaps1, float3(1, 1, 1)) + dot(columntaps2, float3(1, 1, 1));
    linetaps1 /= suml;
    linetaps2 /= suml;
    columntaps1 /= sumc;
    columntaps2 /= sumc;

    pos -= f + 1.5f;

    float3 src[6][6];

    [unroll]
    for (i = 0; i <= 4; i += 2)
    {
        [unroll]
        for (j = 0; j <= 4; j += 2)
        {
            float2 tpos = (pos + uint2(i, j)) * inputPt;
            const float4 sr = Input.GatherRed(TextureSampler, tpos);
            const float4 sg = Input.GatherGreen(TextureSampler, tpos);
            const float4 sb = Input.GatherBlue(TextureSampler, tpos);

			// w z
			// x y
            src[i][j] = float3(sr.w, sg.w, sb.w);
            src[i][j + 1] = float3(sr.x, sg.x, sb.x);
            src[i + 1][j] = float3(sr.z, sg.z, sb.z);
            src[i + 1][j + 1] = float3(sr.y, sg.y, sb.y);
        }
    }
    // final sum and weight normalization

    float3 color = float3(0, 0, 0);
	[unroll]
    for (i = 0; i <= 4; i += 2)
    {
        color += (mul(linetaps1, float3x3(src[0][i], src[2][i], src[4][i])) + mul(linetaps2, float3x3(src[1][i], src[3][i], src[5][i]))) * columntaps1[i / 2] + (mul(linetaps1, float3x3(src[0][i + 1], src[2][i + 1], src[4][i + 1])) + mul(linetaps2, float3x3(src[1][i + 1], src[3][i + 1], src[5][i + 1]))) * columntaps2[i / 2];
    }

	// 抗振铃
    float3 min_sample = min4(src[2][2], src[3][2], src[2][3], src[3][3]);
    float3 max_sample = max4(src[2][2], src[3][2], src[2][3], src[3][3]);
    color = lerp(color, clamp(color, min_sample, max_sample), 0.5);

    return float4(color, 1);
}

technique SpriteBatch
{
    pass
    {
        PixelShader = compile ps_5_0 SpritePixelShader();
    }
}



//!PARAMETER
//!LABEL Anti-ringing Strength
//!DEFAULT 0.5
//!MIN 0
//!MAX 1
//!STEP 0.01
//float ARStrength;

//!TEXTURE
//Texture2D INPUT;

//!TEXTURE
//Texture2D OUTPUT;

//!SAMPLER
//!FILTER POINT
//SamplerState sam : register(s0);

//uint2 inputSize;
//float2 inputPt;

// Define the necessary constants
//float inputWidth;
//float inputHeight;
//float inputPtX;
//float inputPtY;

//#define FIX(c) max(abs(c), 1e-5)
//#define PI 3.14159265359
//#define min4(a, b, c, d) min(min(a, b), min(c, d))
//#define max4(a, b, c, d) max(max(a, b), max(c, d))

//float3 weight3(float x)
//{
//    const float rcpRadius = 1.0f / 3.0f;
//    float3 s = FIX(2.0 * PI * float3(x - 1.5, x - 0.5, x + 0.5));
//	// Lanczos3. Note: we normalize outside this function, so no point in multiplying by radius.
//    return /*radius **/sin(s) * sin(s * rcpRadius) * rcp(s * s);
//}

//struct VertexShaderInput
//{
//    float4 Position : SV_POSITION;
//    float2 TextureCoordinates : TEXCOORD0;
//};

//float4 Pass1(VertexShaderInput input) : SV_Target
//{
//    // Why is this all yellow? Implying x, y = 1, 1 for the entire screen
//    return float4(input.TextureCoordinates.x / 255.0, input.TextureCoordinates.y / 255.0, 0, 1);
//    //if (input.TextureCoordinates.x > 0.99)
//    //{
//    //    return float4(1, 1, 1, 1);
//    //}
//    //return float4(1, 0, 0, 1);
//    //return float4(input.x, input.y, 0, 0.5);
//    //INPUT.Sample(sam, input);
    
// //   float2 pos = input * uint2(inputWidth, inputHeight);
// //   float2 inputPt = float2(inputPtX, inputPtY);

// //   uint i, j;

// //   float2 f = frac(pos.xy + 0.5f);
// //   float3 linetaps1 = weight3(0.5f - f.x * 0.5f);
// //   float3 linetaps2 = weight3(1.0f - f.x * 0.5f);
// //   float3 columntaps1 = weight3(0.5f - f.y * 0.5f);
// //   float3 columntaps2 = weight3(1.0f - f.y * 0.5f);

//	//// make sure all taps added together is exactly 1.0, otherwise some
//	//// (very small) distortion can occur
// //   float suml = dot(linetaps1, float3(1, 1, 1)) + dot(linetaps2, float3(1, 1, 1));
// //   float sumc = dot(columntaps1, float3(1, 1, 1)) + dot(columntaps2, float3(1, 1, 1));
// //   linetaps1 /= suml;
// //   linetaps2 /= suml;
// //   columntaps1 /= sumc;
// //   columntaps2 /= sumc;

// //   pos -= f + 1.5f;

// //   float3 src[6][6];

// //   [unroll]
// //   for (i = 0; i <= 4; i += 2)
// //   {
// //       [unroll]
// //       for (j = 0; j <= 4; j += 2)
// //       {
// //           float2 tpos = (pos + uint2(i, j)) * inputPt;
// //           const float4 sr = INPUT.GatherRed(sam, tpos);
// //           const float4 sg = INPUT.GatherGreen(sam, tpos);
// //           const float4 sb = INPUT.GatherBlue(sam, tpos);

//	//		// w z
//	//		// x y
// //           src[i][j] = float3(sr.w, sg.w, sb.w);
// //           src[i][j + 1] = float3(sr.x, sg.x, sb.x);
// //           src[i + 1][j] = float3(sr.z, sg.z, sb.z);
// //           src[i + 1][j + 1] = float3(sr.y, sg.y, sb.y);
// //       }
// //   }
// //   // final sum and weight normalization

// //   float3 color = float3(0, 0, 0);
//	//[unroll]
// //   for (i = 0; i <= 4; i += 2)
// //   {
// //       color += (mul(linetaps1, float3x3(src[0][i], src[2][i], src[4][i])) + mul(linetaps2, float3x3(src[1][i], src[3][i], src[5][i]))) * columntaps1[i / 2] + (mul(linetaps1, float3x3(src[0][i + 1], src[2][i + 1], src[4][i + 1])) + mul(linetaps2, float3x3(src[1][i + 1], src[3][i + 1], src[5][i + 1]))) * columntaps2[i / 2];
// //   }

//	//// 抗振铃
// //   float3 min_sample = min4(src[2][2], src[3][2], src[2][3], src[3][3]);
// //   float3 max_sample = max4(src[2][2], src[3][2], src[2][3], src[3][3]);
// //   color = lerp(color, clamp(color, min_sample, max_sample), ARStrength);

// //   return float4(color, 1);
//}

////float4 VS(float4 pos : POSITION) : SV_Position
////{
////    return pos;
////}

//technique UpscaleTech
//{
//    pass
//    {
//        //VertexShader = compile vs_5_0 VS();
//        PixelShader = compile ps_5_0 Pass1();
//    }
//}
