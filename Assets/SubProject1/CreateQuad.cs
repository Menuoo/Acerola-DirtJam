using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class CreateQuad : MonoBehaviour
{
    Vector3 position;
    MeshFilter meshFilter;
    Mesh mesh;

    [Header("Prerequisites")]
    public Material material;
    public Light directional;

    [Header("Mesh Settings")]
    public bool regenerate = false;
    public float scale = 1f;
    [Range(2, 1000)]
    public int sideVerts = 2; // minimum 2
    public float sideLength = 10f;


    void Start()
    {
        position = transform.position;
        GetComponent<MeshRenderer>().sharedMaterial = material;
        meshFilter = GetComponent<MeshFilter>();

        UpdateMesh();
    }

    private void Update()
    {
        if (regenerate)
        {
            regenerate = false;
            UpdateMesh();
        }
    }

    private void OnWillRenderObject()
    {
        UpdateMaterial();
    }


    void UpdateMesh()
    {
        mesh = new Mesh();
        mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;

        // Vertices
        Vector3[] vertices = new Vector3[sideVerts * sideVerts];

        float baseX = position.x - sideLength / 2f;
        float baseZ = position.z - sideLength / 2f;
        float step = sideLength / (sideVerts - 1);

        for (int row = 0; row < sideVerts; row++)
        {
            for (int col = 0; col < sideVerts; col++)
            {
                float currentX = baseX + step * row;
                float currentZ = baseZ + step * col;

                vertices[row * sideVerts + col] = new Vector3 (currentX, position.y, currentZ);
            }
        }

        mesh.vertices = vertices;


        // Triangles
        int[] triangles = new int[(sideVerts - 1) * (sideVerts - 1) * 6];
        int i = 0;

        for (int row = 0; row < sideVerts - 1; row++)
        {
            for (int col = 0; col < sideVerts - 1; col++)
            {
                triangles[i++] = row * sideVerts + col;
                triangles[i++] = row * sideVerts + (col + 1);
                triangles[i++] = (row + 1) * sideVerts + col;

                triangles[i++] = row * sideVerts + (col + 1);
                triangles[i++] = (row + 1) * sideVerts + (col + 1);
                triangles[i++] = (row + 1) * sideVerts + col;
            }
        }
        mesh.triangles = triangles;

        Debug.Log("---------------------------------------------");
        Debug.Log("Step: " + step);
        Debug.Log("baseX: " + baseX + ", baseZ: " + baseZ);
        Debug.Log("Number of Triangles: " + triangles.Length / 3);

        mesh.RecalculateBounds();
        mesh.RecalculateNormals();

        meshFilter.mesh = mesh;
        UpdateMaterial();
    }

    void UpdateMaterial()
    {
        Vector3 lightDir = directional.transform.forward;
        material.SetVector("_LightDir", new Vector4(lightDir.x, lightDir.y, lightDir.z, 1));
    }
}
