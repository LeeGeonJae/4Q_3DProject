#pragma once
#include "ResourceBase.h"

#include "physx/PxPhysicsAPI.h"

namespace physics
{
	class MaterialResource : public ResourceBase
	{
	public:
		MaterialResource();
		virtual ~MaterialResource();

	private:
		physx::PxMaterial* mMaterial;
	};
}

