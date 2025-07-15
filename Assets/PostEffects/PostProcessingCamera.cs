using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class PostProcessingCamera : MonoBehaviour
{
    [SerializeField]
    Shader postShader;
    Material postMaterial;

    [SerializeField]
    Color screenTint = Color.white;
    [SerializeField]
    Color chromaticOffset = Color.black;

    [SerializeField]
    int[] addPasses = new int[] { };

    private void Start()
    {
        if (postMaterial == null)
        {
            postMaterial = new Material(postShader);
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        int width = src.width;
        int height = src.height;

        postMaterial.SetColor("_ScreenTint", screenTint);
        postMaterial.SetColor("_ChromaticOffset", chromaticOffset);


        RenderTexture tempRender = RenderTexture.GetTemporary(width, height, 0, src.format);
        Graphics.Blit(src, tempRender, postMaterial, 0);

        Shader.SetGlobalTexture("_GlobalRenderTexture", tempRender);

        RenderTexture nextRender = tempRender;

        /*foreach (int pass in addPasses)
        {
            tempRender = RenderTexture.GetTemporary(width, height, 0, src.format);
            Graphics.Blit(nextRender, tempRender, postMaterial, pass);
            nextRender = tempRender;
        }*/

        Graphics.Blit(nextRender, dest);
        RenderTexture.ReleaseTemporary(tempRender);
        RenderTexture.ReleaseTemporary(nextRender);
    }
}
