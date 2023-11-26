using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class BloomFilter : MonoBehaviour
{
    [SerializeField, Range(1, 16)] private int iterations = 1;
    [SerializeField, Range(0, 10)] private float threshold = 1;
    [SerializeField] private Shader bloomShader;
    private Material bloom;

    const int BoxDownPrefilterPass = 0;
    const int BoxDownPass = 1;
	const int BoxUpPass = 2;
    
	const int ApplyBloomPass = 3;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    void OnRenderImage (RenderTexture source, RenderTexture destination) 
    {
        if (bloom == null) 
        {
			bloom = new Material(bloomShader);
            // Stops the material being saved or shown in hierarchy
			bloom.hideFlags = HideFlags.HideAndDontSave;
		}
        
		bloom.SetFloat("_Threshold", threshold);

        int width = source.width;
		int height = source.height;
        RenderTextureFormat format = source.format;

        RenderTexture[] textures = new RenderTexture[16];


		RenderTexture currentSource =  textures[0] = 
            RenderTexture.GetTemporary(width, height, 0, format);

        Graphics.Blit(source, currentSource, bloom, BoxDownPrefilterPass);

        RenderTexture currentDestination;
        
        int i = 1;
        for (; i < iterations; i++) 
        {
			width /= 2;
			height /= 2;
            if (height < 2 || width < 2)
				break;
			currentDestination = textures[i] =
				RenderTexture.GetTemporary(width, height, 0, format);
			Graphics.Blit(currentSource, currentDestination, bloom, BoxDownPass);
			currentSource = currentDestination;
        }

        for (i -= 2; i >= 0; i--) {
			currentDestination = textures[i];
			textures[i] = null;
			Graphics.Blit(currentSource, currentDestination, bloom, BoxUpPass);
			RenderTexture.ReleaseTemporary(currentSource);
			currentSource = currentDestination;
		}

        bloom.SetTexture("_SourceTex", source);
		Graphics.Blit(currentSource, destination, bloom, ApplyBloomPass);

		RenderTexture.ReleaseTemporary(currentSource);
	}
}
