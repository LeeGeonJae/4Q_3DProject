#pragma once

#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <set>
#include <directxtk\SimpleMath.h>
#include <PxPhysicsAPI.h>

#include <extensions/PxParticleExt.h>

#include "type.h"

namespace PhysicsEngine
{
	class ClothPhysics
	{
	public:
		ClothPhysics(unsigned int id, unsigned int layerNumber);
		~ClothPhysics();

		bool Initialize(const PhysicsClothInfo& info, physx::PxPhysics* physics, physx::PxScene* scene, physx::PxCudaContextManager* cudaContextManager);

		void GetPhysicsCloth(physx::PxCudaContextManager* cudaContextManager, physx::PxCudaContext* cudaContext, PhysicsClothGetData& data);
		void SetPhysicsCloth(physx::PxCudaContextManager* cudaContextManager, physx::PxCudaContext* cudaContext, const PhysicsClothSetData& data);

		inline void SetWorldTransform(const DirectX::SimpleMath::Matrix& position);
		inline void SetTotalClothMass(const float& toTalClothMass);
		inline const DirectX::SimpleMath::Matrix& GetWorldTransform() const;
		inline const float& GetTotalClothMass() const;
		inline const physx::PxPBDParticleSystem* GetParticleSystem() const;
		inline const physx::PxParticleClothBuffer* GetClothBuffer() const;
		inline const physx::ExtGpu::PxParticleClothBufferHelper* GetParticleClothBufferHelper() const;
		inline const std::set<std::pair<unsigned int, unsigned int>>& GetSprings() const;

	private:
		physx::PxU32 id(const physx::PxU32& x, const physx::PxU32& y, const physx::PxU32& numY);
		void extractSpringsData(unsigned int* indices, unsigned int indexSize);
		void settingInfoData(const PhysicsClothInfo& info);
		void settingParticleBuffer(
			const physx::PxU32& numSprings,
			const physx::PxU32& numTriangles,
			const physx::PxU32& numParticles,
			const physx::PxU32& particlePhase,
			const physx::PxReal& particleMass);

		void calculateNormals();

	private:
		unsigned int	mID;
		unsigned int	mLayNumber;

		float			mTotalClothMass;

		DirectX::SimpleMath::Matrix mWorldTransform;
		std::set<std::pair<unsigned int, unsigned int>> mSprings;
		std::vector<std::pair<unsigned int, unsigned int>> mSameVertices;

		physx::PxPBDMaterial* mPBDMaterial;
		physx::PxPBDParticleSystem* mParticleSystem;
		physx::PxParticleClothBuffer* mClothBuffer;
		physx::ExtGpu::PxParticleClothBufferHelper* mClothBufferHelper;

		physx::PxU32* mPhase;
		physx::PxVec4* mPositionInvMass;
		physx::PxVec4* mVelocity;
		std::vector<DirectX::SimpleMath::Vector3> mVertices;
		std::vector<DirectX::SimpleMath::Vector2> mUV;
		std::vector<DirectX::SimpleMath::Vector3> mNormals;
		std::vector<DirectX::SimpleMath::Vector3> mTangents;
		std::vector<DirectX::SimpleMath::Vector3> mBiTangents;
		std::vector<unsigned int> mIndices;
	};

#pragma region GetSet
	void ClothPhysics::SetWorldTransform(const DirectX::SimpleMath::Matrix& position)
	{
		mWorldTransform = position;
	}
	void ClothPhysics::SetTotalClothMass(const float& toTalClothMass)
	{
		mTotalClothMass = toTalClothMass;
	}
	const DirectX::SimpleMath::Matrix& ClothPhysics::GetWorldTransform() const
	{
		return mWorldTransform;
	}
	const float& ClothPhysics::GetTotalClothMass() const
	{
		return mTotalClothMass;
	}
	const physx::PxPBDParticleSystem* ClothPhysics::GetParticleSystem() const
	{
		return mParticleSystem;
	}
	const physx::PxParticleClothBuffer* ClothPhysics::GetClothBuffer() const
	{
		return mClothBuffer;
	}
	const physx::ExtGpu::PxParticleClothBufferHelper* ClothPhysics::GetParticleClothBufferHelper() const
	{
		return mClothBufferHelper;
	}
	const std::set<std::pair<unsigned int, unsigned int>>& ClothPhysics::GetSprings() const
	{
		return mSprings;
	}
#pragma endregion
}

