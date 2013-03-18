package riggedModel {

import away3d.animators.SkeletonAnimationSet;
import away3d.animators.data.Skeleton;
import away3d.containers.ObjectContainer3D;
import away3d.entities.Mesh;
import away3d.events.AssetEvent;
import away3d.events.LoaderEvent;
import away3d.library.AssetLibrary;
import away3d.loaders.parsers.AWD2Parser;
import away3d.materials.TextureMaterial;
import away3d.textures.BitmapTexture;

import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
import com.as3nui.nativeExtensions.air.kinect.data.User;
import com.derschmale.away3d.loading.RotatedMD5MeshParser;
import com.eventsManger.EventsManager;

import flash.events.Event;
import flash.net.URLRequest;
import flash.utils.Dictionary;

public class RiggedModel extends ObjectContainer3D {

	//衣服材质贴图
    [Embed(source="/assets/characters/export/character.jpg")]
	private var BodyMaterial:Class;
	private var TEXTURE_COATS_N:String = "/assets/characters/export/cloth_0001_n.png";
	private var TEXTURE_COATS_S:String = "/assets/characters/export/cloth_0001_s.png";
	private var TEXTURE_COATS_D:String = "/assets/characters/export/cloth_0001_d.png";
	private var TEXTURE_COATS_O:String = "/assets/characters/export/cloth_0001_o.png";
	
	private var TEXTURE_PANTS_N:String = "/assets/characters/export/pants_0001_n.png";
	private var TEXTURE_PANTS_S:String = "/assets/characters/export/pants_0001_s.png";
	private var TEXTURE_PANTS_D:String = "/assets/characters/export/pants_0001_d.png";
	private var TEXTURE_PANTS_O:String = "/assets/characters/export/pants_0001_o.png";
	

	//kinect玩家
    public var user:User;
	//3D mesh
    private var _mesh:Mesh;
	//3d骨架
    private var _skeleton:Skeleton;
	//衣服材质
    private var _bodyMaterial:TextureMaterial;
    //private var _animationController:RiggedModelAnimationControllerByJointPosition;
	private var assetsThatAreloaded : Number = 0;
	private var assetsToLoad : Number = 9;
//	private var MESH_URL:String = "coatPant0001.AWD";
	private var MESH_URL:String = "MaxAWDWorkflow.awd";

	
    public function RiggedModel(user:User) {
        this.user = user;

		AssetLibrary.enableParser(AWD2Parser);
		AssetLibrary.enableParser(RotatedMD5MeshParser);
		AssetLibrary.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
		AssetLibrary.addEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete);
		AssetLibrary.addEventListener(LoaderEvent.LOAD_ERROR, onLoadError);
		
		AssetLibrary.load(new URLRequest("assets/characters/export/coatPant0001.AWD"));
//		AssetLibrary.load(new URLRequest("assets/characters/export/character.md5mesh"));
		AssetLibrary.load(new URLRequest(TEXTURE_COATS_N));
		AssetLibrary.load(new URLRequest(TEXTURE_COATS_S));
		AssetLibrary.load(new URLRequest(TEXTURE_COATS_D));
		AssetLibrary.load(new URLRequest(TEXTURE_COATS_O));
		
		AssetLibrary.load(new URLRequest(TEXTURE_PANTS_N));
		AssetLibrary.load(new URLRequest(TEXTURE_PANTS_S));
		AssetLibrary.load(new URLRequest(TEXTURE_PANTS_D));
		AssetLibrary.load(new URLRequest(TEXTURE_PANTS_O));
    }

	protected function onLoadError(event:LoaderEvent):void
	{
		throw new Error("3d res load error")
	}
	
	/**
	 * Listener function for asset complete event on loader
	 */
	private function onAssetComplete(event:AssetEvent):void
	{
		// To not see these names output in the console, comment the
		// line below with two slash'es, just as you see on this line
		if (event.asset is Mesh)
			handleMesh(event.asset as Mesh);
		if (event.asset is Skeleton)
			handleSkeleton(event.asset as Skeleton);
		
		if (everythingIsLoaded())
			createAnimationController();
	}
	
	private function onResourceComplete(evt:LoaderEvent):void
	{
		assetsThatAreloaded++;
		// check to see if we have all we need
		if (assetsThatAreloaded == assetsToLoad)
		{
			setupScene();
		}
		
	}

    private function handleMesh(mesh:Mesh):void {
		if(mesh == null)return;
        _mesh = mesh;
		
        _bodyMaterial = new TextureMaterial(new BitmapTexture(new BodyMaterial().bitmapData));
        _bodyMaterial.ambientColor = 0x101020;
        _bodyMaterial.ambient = 1;
        _mesh.material = _bodyMaterial;
        addChild(_mesh);
    }
	
	private var cloth:Mesh;
	private var pants : Mesh;
	private function setupScene():void
	{
		//model texture
		cloth = createMesh("coats_0001",TEXTURE_COATS_D,TEXTURE_COATS_N,TEXTURE_COATS_S);
		pants = createMesh("plants_0001",TEXTURE_PANTS_D,TEXTURE_PANTS_N,TEXTURE_PANTS_S);
		videoPanel = Mesh(AssetLibrary.getAsset("videoPlane"));
		
		this.dispatchEvent(new Event("res_load_all"));
	}
	
	public var videoPanel : Mesh;
	
	private function createMesh(modeName : String,diffuseTexture : String,normalTexture : String,specularTexture : String) : Mesh
	{
		var mesh : Mesh = Mesh(AssetLibrary.getAsset(modeName));
		if(mesh == null)return null;
		var material:TextureMaterial = new TextureMaterial(AssetLibrary.getAsset(diffuseTexture) as BitmapTexture);
		material.normalMap = BitmapTexture(AssetLibrary.getAsset(normalTexture));
		material.specularMap = BitmapTexture(AssetLibrary.getAsset(specularTexture));
		material.gloss = 40;
		material.specular = 0.5;
		material.ambientColor = 0xAAAAFF;
		material.ambient = 0.25;
		
		// put our hero center stage and assign our material object
		mesh.scale(10);
		mesh.material = material;
		mesh.castsShadows = true;
		addChild(mesh);
		return mesh;
	}
	


    private function handleSkeleton(skeleton:Skeleton):void {
        _skeleton = skeleton;
    }

    private function everythingIsLoaded():Boolean {
        return (_mesh != null && _skeleton != null);
    }

    private function createAnimationController():void {
        var jointMapping:Dictionary = createMappingForKinectJointsToMeshBones();

        var animationSet:SkeletonAnimationSet = new SkeletonAnimationSet(5);
        animationSet.addAnimation("airkinect", new RiggedModelAnimationNode(user, jointMapping));
		
        var animator:RiggedModelSkeletonAnimator = new RiggedModelSkeletonAnimator(animationSet, _skeleton, false);
        animator.play("airkinect");
        _mesh.animator = animator;
    }

    private function createMappingForKinectJointsToMeshBones():Dictionary {
        var jointMapping:Dictionary = new Dictionary();

        jointMapping[SkeletonJoint.HEAD] = _skeleton.jointIndexFromName("Head");
        jointMapping[SkeletonJoint.NECK] = _skeleton.jointIndexFromName("Neck");
        jointMapping[SkeletonJoint.TORSO] = _skeleton.jointIndexFromName("Spine");

        jointMapping[SkeletonJoint.LEFT_SHOULDER] = _skeleton.jointIndexFromName("RightArm");
        jointMapping[SkeletonJoint.LEFT_ELBOW] = _skeleton.jointIndexFromName("RightForeArm");
        jointMapping[SkeletonJoint.LEFT_HAND] = _skeleton.jointIndexFromName("RightHand");

        jointMapping[SkeletonJoint.RIGHT_SHOULDER] = _skeleton.jointIndexFromName("LeftArm");
        jointMapping[SkeletonJoint.RIGHT_ELBOW] = _skeleton.jointIndexFromName("LeftForeArm");
        jointMapping[SkeletonJoint.RIGHT_HAND] = _skeleton.jointIndexFromName("LeftHand");

        jointMapping[SkeletonJoint.LEFT_HIP] = _skeleton.jointIndexFromName("RightUpLeg");
        jointMapping[SkeletonJoint.LEFT_KNEE] = _skeleton.jointIndexFromName("RightLeg");
        jointMapping[SkeletonJoint.LEFT_FOOT] = _skeleton.jointIndexFromName("RightFoot");

        jointMapping[SkeletonJoint.RIGHT_HIP] = _skeleton.jointIndexFromName("LeftUpLeg");
        jointMapping[SkeletonJoint.RIGHT_KNEE] = _skeleton.jointIndexFromName("LeftLeg");
        jointMapping[SkeletonJoint.RIGHT_FOOT] = _skeleton.jointIndexFromName("LeftFoot");

        return jointMapping;
    }
	
	
	override public function dispose():void {
		AssetLibrary.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete,false);
		AssetLibrary.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, onResourceComplete,false);
		AssetLibrary.removeEventListener(LoaderEvent.LOAD_ERROR, onLoadError,false);
		super.dispose();
	}
}
}