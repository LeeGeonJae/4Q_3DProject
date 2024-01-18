#pragma once

namespace Engine
{
	class SkeletalMesh;
	class Material;
	class Node;
	struct CB_MatrixPalette;

	class SkeletalMeshInstance
	{
	public:
		SkeletalMeshInstance();
		~SkeletalMeshInstance();

	public:
		void Create(SkeletalMesh* _pMeshResource, vector<shared_ptr<Node>>& _pNodeVec, Material* _pMaterial, Matrix* _pTransform);
		void UpdateMatrixPallete(CB_MatrixPalette* pMatrixPallete);

	public:
		inline SkeletalMesh* GetSkeletalMesh();
		inline Material* GetMaterial();
		inline vector<shared_ptr<Node>>& GetNodeVec();
		inline Matrix* GetMatrix();

	private:
		SkeletalMesh* m_pMeshResource;
		Material* m_pMaterial;
		vector<shared_ptr<Node>> m_pNodeVec;
		Matrix* m_pTransform;
	};

	SkeletalMesh* SkeletalMeshInstance::GetSkeletalMesh()
	{
		return m_pMeshResource;
	}
	Material* SkeletalMeshInstance::GetMaterial()
	{
		return m_pMaterial;
	}
	vector<shared_ptr<Node>>& SkeletalMeshInstance::GetNodeVec()
	{
		return m_pNodeVec;
	}
	Matrix* SkeletalMeshInstance::GetMatrix()
	{
		return m_pTransform;
	}
}