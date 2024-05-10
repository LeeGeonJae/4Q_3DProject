#include "pch.h"
#include "CharacterController.h"

#include "CharacterMovement.h"

namespace physics
{
	CharacterController::CharacterController()
		: mID()
		, mLayerNumber()
		, mInputMove()
		, mCharacterMovement(nullptr)
		, mMaterial(nullptr)
		, mPxController(nullptr)
	{
	}

	CharacterController::~CharacterController()
	{
		mPxController->release();
	}

	bool CharacterController::Initialize(const CharacterControllerInfo& info
		, const CharacterMovementInfo& movementInfo
		, physx::PxControllerManager* CCTManager
		, physx::PxMaterial* material
		, std::shared_ptr<CollisionData> collisionData
		, int* collisionMatrix)
	{
		mID = info.id;
		mLayerNumber = info.layerNumber;
		mMaterial = material;

		mCharacterMovement = std::make_shared<CharacterMovement>();
		mCharacterMovement->initialize(movementInfo);

		return true;
	}

	bool CharacterController::Update(float deltaTime)
	{
		// 이동할 변위 벡터
		physx::PxVec3 dispVector;

		// 캐릭터 무브먼트 업데이트로 속도 계산 후
		mCharacterMovement->Update(deltaTime, mInputMove);

		mCharacterMovement->CopyDirectionToPxVec3(dispVector);

		// physx CCT 이동
		physx::PxControllerCollisionFlags collisionFlags = mPxController->move(dispVector, 0.01f, deltaTime, NULL);

		// 바닥과 충돌을 안한다면 떨어짐 상태로 체크
		if (collisionFlags & physx::PxControllerCollisionFlag::eCOLLISION_DOWN)
			mCharacterMovement->SetIsFall(false);
		else
			mCharacterMovement->SetIsFall(true);

		// 입력받은 값 초기화
		mInputMove = {};

		return true;
	}

	void CharacterController::AddMovementInput(const DirectX::SimpleMath::Vector3& input)
	{
		mInputMove += input;
	}
}