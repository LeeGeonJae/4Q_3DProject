#pragma once
#include "ResourceBase.h"

namespace GraphicsEngine
{
	// 건재 : 클래스 선언
	class SkeletonResource;
	class AnimationResource;
	class AnimationNode;
	class Bone;


	// 건재 : 노드 데이터 구조체
	struct NodeData
	{
		string m_Name;
		string m_ParentName;
		vector<string> m_MeshName;
		Matrix m_LocalMatrix;
	};


	// -------------------------------------------------------------------------
	// 건재 : 노드 데이터 리소스 클래스
	// 건재 : 특정 FBX가 가지고 있는 모든 노드 데이터들을 가진 클래스입니다.
	class NodeDataResource : public ResourceBase
	{
	public:
		NodeDataResource();
		virtual ~NodeDataResource();

	public:
		void processNode(const aiNode* _aiNode, const aiScene* _aiScene);

	public:
		inline const vector<NodeData>& GetNodeDataVec();
		inline void SetNodeDataVec(vector<NodeData> _nodeDataVec);
		inline void AddNodeData(NodeData _nodeData);

	private:
		vector<NodeData> m_NodeData;
	};

	// 건재 : NodeDataResource의 Get & Set 함수
	const vector<NodeData>& NodeDataResource::GetNodeDataVec()
	{
		return m_NodeData;
	}
	void NodeDataResource::SetNodeDataVec(vector<NodeData> _nodeDataVec)
	{
		m_NodeData = _nodeDataVec;
	}
	void NodeDataResource::AddNodeData(NodeData _nodeData)
	{
		m_NodeData.push_back(_nodeData);
	}
	// -------------------------------------------------------------------------


	// -------------------------------------------------------------------------
	// 건재 : 노드 클래스
	class Node : public enable_shared_from_this<Node>
	{
	public:
		Node();
		Node(NodeData _nodeData) : m_NodeData(_nodeData) {};
		~Node();

	public:
		void Update(Matrix _modelTransform, float _currentTime);

	private:
		void interpolateAnimationData(float currentTime, Vector3& outPosition, Vector3& outScaling, Quaternion& outRotation);

	public:
		inline const NodeData& GetNodaData();
		inline void SetNodeData(NodeData _nodeData);
		inline shared_ptr<Node> GetParent();
		inline void SetParent(shared_ptr<Node> _node);
		inline const vector<shared_ptr<Node>>& GetNodes();
		inline void SetChildNode(shared_ptr<Node> _node);
		inline shared_ptr<Bone> GetBone();
		inline void SetBone(shared_ptr<Bone> _bone);
		inline shared_ptr<AnimationNode> GetAnimationNode();
		inline void SetAnimationNode(shared_ptr<AnimationNode> _animationNode);
		inline const Matrix& GetLocalTransform();
		inline void SetLocalTransform(Matrix _transform);
		inline const Matrix& GetWorldTransform();

	private:
		NodeData m_NodeData;

		shared_ptr<Node> m_pParent;
		vector<shared_ptr<Node>> m_pChildrenVec;

		shared_ptr<Bone> m_pBone;
		shared_ptr<AnimationNode> m_pAnimationNode;

		Matrix m_Local;
		Matrix m_World;
	};

	// 건재 : Node의 Get & Set 함수
	const NodeData& Node::GetNodaData()
	{
		return m_NodeData;
	}
	void Node::SetNodeData(NodeData _nodeData)
	{
		m_NodeData = _nodeData;
	}
	shared_ptr<Node> Node::GetParent()
	{
		return m_pParent;
	}
	void Node::SetParent(shared_ptr<Node> _node)
	{
		m_pParent = _node;
		m_pParent->SetChildNode(shared_from_this());
	}
	const vector<shared_ptr<Node>>& Node::GetNodes()
	{
		return m_pChildrenVec;
	}
	void Node::SetChildNode(shared_ptr<Node> _node)
	{
		m_pChildrenVec.push_back(_node);
	}
	shared_ptr<Bone> Node::GetBone()
	{
		return m_pBone;
	}
	void Node::SetBone(shared_ptr<Bone> _bone)
	{
		m_pBone = _bone;
	}
	shared_ptr<AnimationNode> Node::GetAnimationNode()
	{
		return m_pAnimationNode;
	}
	void Node::SetAnimationNode(shared_ptr<AnimationNode> _animationNode)
	{
		m_pAnimationNode = _animationNode;
	}
	const Matrix& Node::GetLocalTransform()
	{
		return m_Local;
	}
	void Node::SetLocalTransform(Matrix _transform)
	{
		m_Local = _transform;
	}
	const Matrix& Node::GetWorldTransform()
	{
		return m_World;
	}
	// -------------------------------------------------------------------------
}