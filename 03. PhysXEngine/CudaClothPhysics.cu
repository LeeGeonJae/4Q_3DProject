#include "CudaClothPhysics.h"
#include "cudamanager\PxCudaContext.h"

#include <iostream>

#pragma comment (lib, "cudart.lib")

__device__ physx::PxVec2 Sub(const physx::PxVec2& lhs, const physx::PxVec2& rhs)
{
	physx::PxVec2 result;
    result.x = lhs.x - rhs.x;
    result.y = lhs.y - rhs.y;
    return result;
}

__device__ physx::PxVec4 Sub(const physx::PxVec4& lhs, const physx::PxVec4& rhs)
{
	physx::PxVec4 result;
    result.x = lhs.x - rhs.x;
    result.y = lhs.y - rhs.y;
    result.z = lhs.z - rhs.z;
	result.w = lhs.w - rhs.w;
    return result;
}

__device__ physx::PxVec3 cross(const physx::PxVec4& a, const physx::PxVec4& b) {
    return {
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
    };
}

__device__ float DotProduct(const physx::PxVec3& a, const physx::PxVec3& b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

__device__ void NormalizeVector(physx::PxVec3& vectors)
{
    float length = vectors.x + vectors.y + vectors.z;
    if (length > 0) {
        vectors.x /= length;
        vectors.y /= length;
        vectors.z /= length;
    }
}

// CUDA 커널 함수 정의
__global__ void CalculateNormals(
	physx::PxVec4* vertices,
	physx::PxVec2* uvs,
    unsigned int vertexSize,
    unsigned int* indices,
    unsigned int indexSize,
    physics::PhysicsVertex* buffer)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= indexSize / 3) return;

    unsigned int i0 = indices[idx * 3];
    unsigned int i1 = indices[idx * 3 + 1];
    unsigned int i2 = indices[idx * 3 + 2];

    physx::PxVec4 v0 = vertices[i0];
    physx::PxVec4 v1 = vertices[i1];
    physx::PxVec4 v2 = vertices[i2];
	v0.z = -v0.z;
	v1.z = -v1.z;
	v2.z = -v2.z;

    physx::PxVec2 uv0 = uvs[i0];
    physx::PxVec2 uv1 = uvs[i1];
    physx::PxVec2 uv2 = uvs[i2];

    physx::PxVec4 edge1 = Sub(v1, v0);
    physx::PxVec4 edge2 = Sub(v2, v0);

	physx::PxVec2 deltaUV1 = Sub(uv1, uv0);
	physx::PxVec2 deltaUV2 = Sub(uv2, uv0);

    float f = 1.0f / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y);

	physx::PxVec3 tangent;
    tangent.x = f * (deltaUV2.y * edge1.x - deltaUV1.y * edge2.x);
    tangent.y = f * (deltaUV2.y * edge1.y - deltaUV1.y * edge2.y);
    tangent.z = f * (deltaUV2.y * edge1.z - deltaUV1.y * edge2.z);
    NormalizeVector(tangent);

	physx::PxVec3 bitangent;
    bitangent.x = f * (-deltaUV2.x * edge1.x + deltaUV1.x * edge2.x);
    bitangent.y = f * (-deltaUV2.x * edge1.y + deltaUV1.x * edge2.y);
    bitangent.z = f * (-deltaUV2.x * edge1.z + deltaUV1.x * edge2.z);
    NormalizeVector(bitangent);

	physx::PxVec3 normal = cross(edge1, edge2);
    NormalizeVector(normal);

	buffer[i0].position.x = v0.x;
	buffer[i0].position.y = v0.y;
	buffer[i0].position.z = v0.z;

	buffer[i1].position.x = v1.x;
	buffer[i1].position.y = v1.y;
	buffer[i1].position.z = v1.z;

	buffer[i2].position.x = v2.x;
	buffer[i2].position.y = v2.y;
	buffer[i2].position.z = v2.z;

    buffer[i0].normal.x += normal.x;
    buffer[i0].normal.y += normal.y;
    buffer[i0].normal.z += normal.z;

    buffer[i1].normal.x += normal.x;
    buffer[i1].normal.y += normal.y;
    buffer[i1].normal.z += normal.z;

    buffer[i2].normal.x += normal.x;
    buffer[i2].normal.y += normal.y;
    buffer[i2].normal.z += normal.z;

    buffer[i0].tangent.x += tangent.x;
    buffer[i0].tangent.y += tangent.y;
    buffer[i0].tangent.z += tangent.z;

    buffer[i1].tangent.x += tangent.x;
    buffer[i1].tangent.y += tangent.y;
    buffer[i1].tangent.z += tangent.z;

    buffer[i2].tangent.x += tangent.x;
    buffer[i2].tangent.y += tangent.y;
    buffer[i2].tangent.z += tangent.z;

    buffer[i0].biTangent.x += bitangent.x;
    buffer[i0].biTangent.y += bitangent.y;
    buffer[i0].biTangent.z += bitangent.z;

    buffer[i1].biTangent.x += bitangent.x;
    buffer[i1].biTangent.y += bitangent.y;
    buffer[i1].biTangent.z += bitangent.z;

    buffer[i2].biTangent.x += bitangent.x;
    buffer[i2].biTangent.y += bitangent.y;
    buffer[i2].biTangent.z += bitangent.z;
}

namespace physics
{
	CudaClothPhysics::CudaClothPhysics(unsigned int id, unsigned int layerNumber)
		: mID(id)
		, mLayNumber(layerNumber)
		, mTotalClothMass()
		, mWorldTransform()
		, mSprings()
		, mPBDMaterial(nullptr)
		, mParticleSystem(nullptr)
		, mClothBuffer(nullptr)
		, mClothBufferHelper(nullptr)
		, mPhase(nullptr)
		, mPositionInvMass(nullptr)
		, mVelocity(nullptr)
		, mVertices()
		, mIndices()
	{
	}
	CudaClothPhysics::~CudaClothPhysics()
	{
	}

	bool CudaClothPhysics::Initialize(const PhysicsClothInfo& info, physx::PxPhysics* physics, physx::PxScene* scene, physx::PxCudaContextManager* cudaContextManager)
	{
		int deviceCount;
		cudaError_t cudaStatus = cudaGetDeviceCount(&deviceCount);
		if (cudaStatus != cudaSuccess || deviceCount == 0) {
			std::cerr << "CUDA 디바이스 초기화 실패" << std::endl;
			return false;
		}

		cudaStatus = cudaSetDevice(0); // 첫 번째 CUDA 디바이스 사용
		if (cudaStatus != cudaSuccess) {
			std::cerr << "CUDA 디바이스 설정 실패" << std::endl;
			return false;
		}

		if (cudaContextManager == nullptr)
			return false;

		settingInfoData(info);
		extractSpringsData(info.indices, info.indexSize);

		// 재료(Material) 설정
		mPBDMaterial = physics->createPBDMaterial(
			info.materialInfo.friction,
			info.materialInfo.damping,
			info.materialInfo.adhesion,
			info.materialInfo.viscosity,
			info.materialInfo.vorticityConfinement,
			info.materialInfo.surfaceTension,
			info.materialInfo.cohesion,
			info.materialInfo.lift,
			info.materialInfo.drag,
			info.materialInfo.cflCoefficient,
			info.materialInfo.gravityScale);

		createClothParticle(physics, scene, cudaContextManager);

		return true;
	}

	bool areVerticesEqual(const DirectX::SimpleMath::Vector3& vertex1, const DirectX::SimpleMath::Vector3& vertex2, float epsilon = 1e-6) {
		return (std::abs(vertex1.x - vertex2.x) < epsilon) &&
			(std::abs(vertex1.y - vertex2.y) < epsilon) &&
			(std::abs(vertex1.z - vertex2.z) < epsilon);
	}

	void CudaClothPhysics::extractSpringsData(unsigned int* indices, unsigned int indexSize)
	{
		// 삼각형 단위로 인덱스를 순회
		for (size_t i = 0; i < indexSize; i += 3)
		{
			unsigned int v1 = indices[i];
			unsigned int v2 = indices[i + 1];
			unsigned int v3 = indices[i + 2];

			// 정렬된 순서로 vertex 쌍을 추가하여 중복된 선분 방지
			auto addEdge = [this](unsigned int a, unsigned int b)
				{
					if (a > b) std::swap(a, b);
					mSprings.insert({ a, b });
				};

			addEdge(v1, v2);
			addEdge(v2, v3);
			addEdge(v3, v1);
		}

		mSameVertices.reserve(mVertices.size() / 3);
		for (int i = 0; i < mVertices.size(); i++)
		{
			for (int j = i + 1; j < mVertices.size(); j++)
			{
				if (areVerticesEqual(mVertices[i], mVertices[j]))
				{
					mSprings.insert({ i, j });
					mSameVertices.push_back({ i, j });
				}
			}
		}
	}

	void CudaClothPhysics::settingInfoData(const PhysicsClothInfo& info)
	{
		mWorldTransform = info.worldTransform;
		mTotalClothMass = info.totalClothMass;

		mIndices.resize(info.indexSize);
		memcpy(mIndices.data(), info.indices, info.indexSize * sizeof(unsigned int));

		mVertices.resize(info.vertexSize);
		mUV.resize(info.vertexSize);
		for (int i = 0; i < info.vertexSize; i++)
		{
			mVertices[i].x = info.vertices[i].x;
			mVertices[i].y = info.vertices[i].y;
			mVertices[i].z = -info.vertices[i].z;
			mUV[i] = info.uv[i];
		}
	}

	void CudaClothPhysics::createClothParticle(physx::PxPhysics* physics, physx::PxScene* scene, physx::PxCudaContextManager* cudaContextManager)
	{
		// 입자 및 스프링, 삼각형의 개수 계산
		const physx::PxU32 numParticles = mVertices.size();	// 입자 갯수
		const physx::PxU32 numSprings = mSprings.size();	// 입자 하나당 이웃하는 입자들에 스프링 값을 가지는데, 그 스프링 갯수
		const physx::PxU32 numTriangles = mIndices.size() / 3;	// 삼각형 갯수

		// 입자 시스템의 설정
		const physx::PxReal particleMass = mTotalClothMass / mVertices.size();
		const physx::PxReal restOffset = 2.f;

		// 입자 시스템 생성
		mParticleSystem = physics->createPBDParticleSystem(*cudaContextManager);

		mParticleSystem->setRestOffset(1.f);
		mParticleSystem->setContactOffset(restOffset + 0.02f);
		mParticleSystem->setParticleContactOffset(restOffset + 0.02f);
		mParticleSystem->setSolidRestOffset(restOffset);

		// 씬에 입자 시스템 추가
		scene->addActor(*mParticleSystem);

		// 입자의 상태를 저장하는 버퍼 생성
		const physx::PxU32 particlePhase = mParticleSystem->createPhase(mPBDMaterial, physx::PxParticlePhaseFlags(
			physx::PxParticlePhaseFlag::eParticlePhaseSelfCollideFilter | physx::PxParticlePhaseFlag::eParticlePhaseSelfCollide));

		mClothBufferHelper = physx::ExtGpu::PxCreateParticleClothBufferHelper(1, numTriangles, numSprings, numParticles, cudaContextManager);
		// 입자, 스프링 삼각형의 상태를 저장하기 위한 버퍼 할당
		mPhase = cudaContextManager->allocPinnedHostBuffer<physx::PxU32>(numParticles);
		mPositionInvMass = cudaContextManager->allocPinnedHostBuffer<physx::PxVec4>(numParticles);
		mVelocity = cudaContextManager->allocPinnedHostBuffer<physx::PxVec4>(numParticles);

		settingParticleBuffer(numSprings, numTriangles, numParticles, particlePhase, particleMass);
		createCloth(numParticles, cudaContextManager);
	}

	float calculateVectorMagnitude(const DirectX::SimpleMath::Vector3& point1, const DirectX::SimpleMath::Vector3& point2) {
		float dx = point2.x - point1.x;
		float dy = point2.y - point1.y;
		float dz = point2.z - point1.z;

		return std::sqrt(dx * dx + dy * dy + dz * dz);
	}

	void CudaClothPhysics::settingParticleBuffer(
		const physx::PxU32& numSprings,
		const physx::PxU32& numTriangles,
		const physx::PxU32& numParticles,
		const physx::PxU32& particlePhase,
		const physx::PxReal& particleMass)
	{
		const physx::PxReal stretchStiffness = 100.f;
		const physx::PxReal shearStiffness = 100.f;
		const physx::PxReal springDamping = 0.1f;

		// 파티클 스프링 및 트라이앵글 생성
		physx::PxArray<physx::PxParticleSpring> springs;
		springs.reserve(numSprings);
		physx::PxArray<physx::PxU32> triangles;
		triangles.reserve(numTriangles * 3);

		// 입자 상태 저장
		for (int i = 0; i < numParticles; i++)
		{
			mPositionInvMass[i] = physx::PxVec4(mVertices[i].x, mVertices[i].y + 300.f, mVertices[i].z, 1.f / particleMass);
			mPhase[i] = particlePhase;
			mVelocity[i] = physx::PxVec4(0.f);
		}

		// 스프링 추가
		for (auto line : mSprings)
		{
			physx::PxParticleSpring spring = { line.first, line.second, calculateVectorMagnitude(mVertices[line.first], mVertices[line.second]), stretchStiffness, springDamping, 0 };
			springs.pushBack(spring);
		}

		// 삼각형 추가
		for (int i = 0; i < mIndices.size(); i += 3)
		{
			triangles.pushBack(mIndices[i]);
			triangles.pushBack(mIndices[i + 1]);
			triangles.pushBack(mIndices[i + 2]);
		}

		// 생성된 스프링 및 삼각형 수가 예상대로 생성되었는지 확인
		PX_ASSERT(numSprings == springs.size());
		PX_ASSERT(numTriangles == triangles.size() / 3);

		// 천막의 버퍼에 데이터 추가
		mClothBufferHelper->addCloth(0.f, 0.f, 0.f, triangles.begin(), numTriangles, springs.begin(), numSprings, mPositionInvMass, numParticles);
	}

	void CudaClothPhysics::createCloth(const physx::PxU32& numParticles, physx::PxCudaContextManager* cudaContextManager)
	{
		// 입자의 상태를 나타내는 버퍼 설명
		physx::ExtGpu::PxParticleBufferDesc bufferDesc;
		bufferDesc.maxParticles = numParticles;
		bufferDesc.numActiveParticles = numParticles;
		bufferDesc.positions = mPositionInvMass;
		bufferDesc.velocities = mVelocity;
		bufferDesc.phases = mPhase;

		// 천막의 설명 가져오기
		const physx::PxParticleClothDesc& clothDesc = mClothBufferHelper->getParticleClothDesc();

		// 입자 천막의 전처리기 생성
		physx::PxParticleClothPreProcessor* clothPreProcessor = PxCreateParticleClothPreProcessor(cudaContextManager);

		// 입자 천막 분할 및 처리
		physx::PxPartitionedParticleCloth output;
		clothPreProcessor->partitionSprings(clothDesc, output);
		clothPreProcessor->release();

		// 천막 버퍼 생성
		mClothBuffer = physx::ExtGpu::PxCreateAndPopulateParticleClothBuffer(bufferDesc, clothDesc, output, cudaContextManager);
		mParticleSystem->addParticleBuffer(mClothBuffer);

		// 버파 해제
		mClothBufferHelper->release();

		// 할당된 메모리 해제
		//cudaContextManager->freePinnedHostBuffer(mPositionInvMass);
		cudaContextManager->freePinnedHostBuffer(mVelocity);
		cudaContextManager->freePinnedHostBuffer(mPhase);
	}

	bool CudaClothPhysics::RegisterD3D11BufferWithCUDA(ID3D11Buffer* buffer)
	{
		cudaError_t cudaStatus = cudaGraphicsD3D11RegisterResource(&mCudaResource, buffer, cudaGraphicsRegisterFlagsNone);
		if (cudaStatus != cudaSuccess)
		{
			std::cerr << "Direct3D 리소스 등록 실패" << std::endl;
			return false;
		}
		return true;
	}

	bool CudaClothPhysics::UpdatePhysicsCloth(physx::PxCudaContextManager* cudaContextManager)
	{
		// CUDA 리소스를 매핑
		cudaError_t cudaStatus = cudaGraphicsMapResources(1, &mCudaResource);
		//if (cudaStatus != cudaSuccess) {
		//	std::cerr << "cudaGraphicsMapResources 실패: " << cudaGetErrorString(cudaStatus) << std::endl;
		//	return false;
		//}

		// CUDA 포인터 가져오기
		void* devPtr = nullptr;
		size_t size = 0;
		cudaGraphicsResourceGetMappedPointer(&devPtr, &size, mCudaResource);
		//if (cudaStatus != cudaSuccess) {
		//	std::cerr << "cudaGraphicsResourceGetMappedPointer 실패: " << cudaGetErrorString(cudaStatus) << std::endl;
		//	return false;
		//}

		unsigned int deviceVertexSize = mVertices.size();
		unsigned int deviceIndexSize = mIndices.size();

		physx::PxVec2* d_uvs;
		unsigned int* d_indices;

		cudaMalloc(&d_uvs, mUV.size() * sizeof(DirectX::SimpleMath::Vector2));
		cudaMalloc(&d_indices, mIndices.size() * sizeof(unsigned int));
		cudaMemcpy(d_uvs, mUV.data(), mUV.size() * sizeof(DirectX::SimpleMath::Vector2), cudaMemcpyKind::cudaMemcpyHostToDevice);
		cudaMemcpy(d_indices, mIndices.data(), mIndices.size() * sizeof(unsigned int), cudaMemcpyKind::cudaMemcpyHostToDevice);


		int particleSize = mClothBuffer->getNbActiveParticles();
		physx::PxVec4* particle = mClothBuffer->getPositionInvMasses();

		cudaContextManager->acquireContext();
		physx::PxCudaContext* cudaContext = cudaContextManager->getCudaContext();

		std::vector<physx::PxVec4> vertex;
		vertex.resize(particleSize);

		cudaContext->memcpyDtoH(vertex.data(), CUdeviceptr(particle), sizeof(physx::PxVec4) * particleSize);

		for (int i = 0; i < particleSize; i++)
		{
			mVertices[i].x = vertex[i].x;
			mVertices[i].y = vertex[i].y;
			mVertices[i].z = -vertex[i].z;
		}

		int threadsPerBlock = 256;
		int blocksPerGrid = (mIndices.size() / 3 + threadsPerBlock - 1) / threadsPerBlock;

		// CUDA 함수 실행
		CalculateNormals <<<blocksPerGrid, threadsPerBlock>>> (
			particle, d_uvs, deviceVertexSize, d_indices, deviceIndexSize, (PhysicsVertex*)devPtr);

		cudaDeviceSynchronize();

		// CUDA 리소스를 언매핑
		cudaGraphicsUnmapResources(1, &mCudaResource);

		// 메모리 해제
		cudaFree(d_uvs);
		cudaFree(d_indices);

		return false;
	}

	void CudaClothPhysics::GetPhysicsCloth(physx::PxCudaContextManager* cudaContextManager, physx::PxCudaContext* cudaContext, PhysicsClothGetData& data)
	{
	}

	void CudaClothPhysics::SetPhysicsCloth(physx::PxCudaContextManager* cudaContextManager, physx::PxCudaContext* cudaContext, const PhysicsClothSetData& data)
	{

	}
}
