#pragma once

#include <PxPhysicsAPI.h>

namespace physics
{
	class Physics
	{
	public:
		Physics();
		~Physics();

		/// <summary>
		/// 기본 PhysX을 세팅합니다.
		/// </summary>
		void Initialize();
		
		/// <summary>
		/// PhysX Visual Debugger 프로그램에 연결할 물리 공간을 세팅합니다.
		/// </summary>
		/// <param name="scene"></param>
		void SettingPVDClient(physx::PxScene* scene);

		/// <summary>
		/// Physics를 반환합니다.
		/// </summary>
		inline physx::PxPhysics* GetPhysics();
		
		/// <summary>
		/// CpuDispatcher를 반환합니다.
		/// </summary>
		inline physx::PxDefaultCpuDispatcher* GetDispatcher();

	private:
		physx::PxDefaultAllocator		mDefaultAllocatorCallback;
		physx::PxDefaultErrorCallback	mDefaultErrorCallback;
		physx::PxTolerancesScale		mToleranceScale;
		physx::PxDefaultCpuDispatcher*	mDispatcher;

		// physx
		physx::PxFoundation*			mFoundation;
		physx::PxPhysics*				mPhysics;

		// PVD
		physx::PxPvd*					mPvd;
		physx::PxPvdSceneClient*		mPvdClient;
	};

	physx::PxPhysics* Physics::GetPhysics()
	{
		return mPhysics;
	}
	physx::PxDefaultCpuDispatcher* Physics::GetDispatcher()
	{
		return mDispatcher;
	}
}


