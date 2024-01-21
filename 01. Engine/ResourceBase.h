#pragma once

namespace Engine
{
	// 건재 : 리소스 타입 열거형
	enum class ResourceType
	{
		None = 0,
		StaticMesh,
		SkeletalMesh,
		Shader,
		Material,
		Texture,
		Animation,
		Bone,
		NodeData,

		End
	};

	// 건재 : 리소스 타입의 갯수
	enum
	{
		RESOURCE_TYPE_COUNT = static_cast<UINT>(ResourceType::End)
	};

	// -------------------------------------------------------------------------
	// 건재 : 리소스 기반 클래스
	class ResourceBase : public enable_shared_from_this<ResourceBase>
	{
	public:
		ResourceBase(ResourceType _type);
		virtual ~ResourceBase();

	public:
		inline const ResourceType& GetResourceType();
		inline const string& GetName();
		inline void SetName(string _name);

	protected:
		ResourceType m_ResourceType;
		string m_Name;
	};

	// 건재 : ResourceBase의 Get & Set 함수
	const ResourceType& ResourceBase::GetResourceType()
	{
		return m_ResourceType;
	}
	const string& ResourceBase::GetName()
	{
		return m_Name;
	}
	void ResourceBase::SetName(string _name)
	{
		m_Name = _name;
	}
	// -------------------------------------------------------------------------
}
