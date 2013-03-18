package {
	
	import away3d.animators.data.SkeletonPose;
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.materials.ColorMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SphereGeometry;
	import away3d.textures.BitmapTexture;
	
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectSettings;
	import com.as3nui.nativeExtensions.air.kinect.constants.CameraResolution;
	import com.as3nui.nativeExtensions.air.kinect.constants.DeviceState;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.CameraImageEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.DeviceEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.recorder.KinectPlayer;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	import riggedModel.RiggedModel;
	
	import ru.inspirit.asfeat.ASFEAT;
	import ru.inspirit.asfeat.IASFEAT;
	import ru.inspirit.asfeat.detect.ASFEATReference;
	import ru.inspirit.asfeat.event.ASFEATDetectionEvent;
	
	[SWF(width = "512",height = "480",frameRate = "60")]
	public class WxKinectDemo extends DemoBase {
		[Embed(source="./assets/def_data.ass", mimeType="application/octet-stream")]
		private static const data_ass1:Class;
		
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var device:Kinect;
		private var player:KinectPlayer;
		private var rgbBitmap:Bitmap;
		private var rgbSkeletonContainer:Sprite;
		private var riggedModels:Vector.<RiggedModel>;
		
		public var asfeat:ASFEAT;
		public var asfeatLib:IASFEAT;
		
		override protected function startDemoImplementation():void 
		{
			riggedModels = new Vector.<RiggedModel>();
			asfeat = new ASFEAT(null);
			asfeat.addEventListener( Event.INIT, initAsFeat ); 
			
			startAway3d();
			startKinect();			
			setSize(512,512);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrameHandler, false, 0, true);
		}
		protected function initAsFeat(e:Event = null):void
		{
			initASFEAT();
		}
		public var maxPointsToDetect:int = 300; // max point to allow on the screen
		public var maxReferenceObjects:int = 1; // max reference objects to be used
		public var maxTransformError:Number = 10 * 10;

		protected function initASFEAT():void
		{
			asfeat.removeEventListener( Event.INIT, init );
			asfeatLib = asfeat.lib;
			
			// init our engine
			asfeatLib.init( 640, 480, maxPointsToDetect, maxReferenceObjects, maxTransformError, stage );
			
			// indexing reference data will result in huge
			// speed up during matching (see docs for more info)
			// !!! u always need to setup indexing even if u dont plan to use it !!!
			asfeatLib.setupIndexing(12, 10, true);
			
			// but u can switch it off if u want
			asfeatLib.setUseLSHDictionary(true);
			
			// add reference object
			asfeatLib.addReferenceObject( ByteArray( new data_ass1 ));
	
			
			// add event listeners
			asfeatLib.addListener( ASFEATDetectionEvent.DETECTED, onModelDetected );
			
			// ATTENTION 
			// limit the amount of references to be detected per frame
			// if u have only one reference u can skip this option
			asfeatLib.setMaxReferencesPerFrame(1);
		}
		
		protected function onModelDetected(e:ASFEATDetectionEvent):void
		{
			var refList:Vector.<ASFEATReference> = e.detectedReferences;
			var ref:ASFEATReference;
			var n:int = e.detectedReferencesCount;
			var state:String;
			
			for(var i:int = 0; i < n; ++i)
			{
				ref = refList[i];
				state = ref.detectType;
				
				//				models[0].setTransform( ref.rotationMatrix, ref.translationVector, ref.poseError, mirror );
				if(state == '_detect')
				{
					trace( '\nmathed: ' + ref.matchedPointsCount );
				}
				trace( '\nfound id: ' + ref.id );
			}

		}
		
		private function startAway3d():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			
			scene = new Scene3D();
			camera = new Camera3D();
			
			view = new View3D();
			view.scene = scene;
			view.camera = camera;
			camera.z = -422;
			
			//抗混叠
			view.width = 512;
			view.height = 512;
			view.backgroundColor = 0x000000;
			addChild(view);

			addVideoPlane();
		}
		
		private var _videoMesh : Mesh;//videoPlane
		public   function addVideoPlane():void
		{
			var tex:BitmapData = new BitmapData(512, 512);
			var mat : TextureMaterial = new TextureMaterial(new BitmapTexture(tex),true,true);
			
			_videoMesh = new Mesh(new PlaneGeometry(512,512),mat);
			_videoMesh.rotationX = -90;
			scene.addChild(_videoMesh);
		}
		
		
		private function changPointToLocalVideo(posx : int,posy : int) : Vector3D
		{
			var v3d : Vector3D = new Vector3D(posx - view.width/2,0,view.height/2 - posy );
			return v3d;
		}
		
		private function startKinect():void
		{
			// TODO Auto Generated method stub
			rgbBitmap = new Bitmap();
			this.addChild(rgbBitmap);
			
			rgbSkeletonContainer = new Sprite();
			addChild(rgbSkeletonContainer);
			
			var settings:KinectSettings = new KinectSettings();
			settings.rgbEnabled = true;
			settings.rgbResolution = CameraResolution.RESOLUTION_640_480;
			settings.skeletonEnabled = true;
			settings.skeletonMirrored = true;
			
			player = new KinectPlayer();
			player.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
			player.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
			player.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, onRenderVideoHandler, false, 0, true);
			player.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler, false, 0, true);
			player.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler, false, 0, true);
			
			
			//use kinect when the player / simulator is not used
			if (player.state == DeviceState.STOPPED && Kinect.isSupported()) {
				device = Kinect.getDevice();
				device.addEventListener(DeviceEvent.STARTED, kinectStartedHandler, false, 0, true);
				device.addEventListener(DeviceEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				device.addEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, onRenderVideoHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler, false, 0, true);
				device.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler, false, 0, true);
				device.start(settings);
			}
		}
		
		protected function onRenderVideoHandler(event:CameraImageEvent):void {
			//2D显示
//			rgbBitmap.bitmapData = event.imageData;
//			rgbBitmap.x = 650;
			//3d显示
			asfeatLib.detect( event.imageData);

			
			var bmd : BitmapData = new BitmapData(512,512);
			bmd.draw(new Bitmap(event.imageData));
			
			var mat : TextureMaterial = new TextureMaterial(new BitmapTexture(bmd));	
			if(_videoMesh)
				_videoMesh.material = mat;
		}
		
		protected function kinectStartedHandler(event:DeviceEvent):void {
			if (event.target == device) {
				trace("Kinect started");
			}
			else {
				trace("Kinect Player started");
			}
		}
		
		protected function kinectStoppedHandler(event:DeviceEvent):void {
			if (event.target == player) {
				trace("Kinect stopped");
			}
			else {
				trace(" Kinect Player stopped");
			}
		}

		/**
		 *识别到人体骨骼后，开始创建模型
		 * @param event
		 * 
		 */		
		protected function usersWithSkeletonAddedHandler(event:UserEvent):void {
			for each(var user:User in event.users) {
				createRiggedModelForUser(user);
			}
		}
		
		/**
		 *开始构建3D衣服模型 
		 * @param user
		 * 
		 */		
		private var _self : RiggedModel;
		private function createRiggedModelForUser(user:User):void 
		{

			var model:RiggedModel = new RiggedModel(user);
			_self = model;
			_self.visible = false;

		
			riggedModels.push(model);
			scene.addChild(model);

		}
		
		
		public static var videoPanel : Mesh;
		
		protected function usersWithSkeletonRemovedHandler(event:UserEvent):void {
			for each(var user:User in event.users) {
				destroyRiggedModelForUser(user);
			}
		}
		
		private function destroyRiggedModelForUser(user:User):void {
			var index:int = -1;
			for (var i:int = 0; i < riggedModels.length; i++) {
				if (riggedModels[i].user == user) {
					scene.removeChild(riggedModels[i]);
				}
			}
			if (index > -1)
				riggedModels.splice(index, 1);
			
			_hasScale =false;
		}
		
		private var user : User;
		private var _hasScale : Boolean;
		protected function onEnterFrameHandler(event:Event):void {
			view.render();
			if (rgbSkeletonContainer != null) 
			{
				rgbSkeletonContainer.graphics.clear();
				if(_ballGroup.length >0)
				{
					for each(var m : Mesh in _ballGroup)
					{
						m.parent.removeChild(m);
						m.dispose();
					}
					_ballGroup.length = 0;
				}
				if (device != null) 
					drawUsers(device.usersWithSkeleton);
				
				if (player != null) 
					drawUsers(player.users);
				
				if(_self&&_center)
				{
					_self.x = _center.x - 300;
					_self.y = _center.y - 360;//向下为减少
				}
				
				if(this.user&&this._self)
				{
					var sw : int =  (Math.abs(user.leftShoulder.position.world.x - user.rightShoulder.position.world.x)*1.3)/10;
					var scale : Number = sw/10*.2;
					
					var h : int = (Math.abs(user.head.position.world.y - user.leftFoot.position.world.y - 50) +Math.abs(user.head.position.world.y - user.neck.position.world.y) + 0.1);
					var scaleB : Number = (h -1000)/100*.1;
					
					
					var endScale : Number = (scale + scaleB)/2 - 0.05;
					var bc : int = (Math.abs(user.leftShoulder.position.world.x - user.leftHand.position.world.x));
					if((bc/10) > 40&&_hasScale == false)
					{
						_hasScale = true;
						_self.visible = true;
						_self.scale(endScale);
					}
					if((user.leftHand.position.world.y - user.head.position.world.y) > 0)
					{
						_self.visible = false;
						_self.scaleX = _self.scaleY = _self.scaleZ = 1;
						_hasScale = false;
					}
				}
			}
		}
		
		private var _scale : Number;
		private var _center : Point = new Point();
		private var _z : int;
		private function drawUsers(users:Vector.<User>):void {
			for each(var user:User in users) {
				this.user = user;
				_center.x = user.getJointByName("right_hip").position.rgb.x;
				_center.y = user.getJointByName("right_hip").position.rgb.y;
				_z = user.getJointByName("right_hip").position.world.z;
				
			
//				//关节之间的连结线
//				drawRGBBone(user.leftHand, user.leftElbow);
//				drawRGBBone(user.leftElbow, user.leftShoulder);
//				drawRGBBone(user.leftShoulder, user.neck);
//				
//				drawRGBBone(user.rightHand, user.rightElbow);
//				drawRGBBone(user.rightElbow, user.rightShoulder);
//				drawRGBBone(user.rightShoulder, user.neck);
//				
//				drawRGBBone(user.head, user.neck);
//				drawRGBBone(user.torso, user.neck);
//				
//				drawRGBBone(user.torso, user.leftHip);
//				drawRGBBone(user.leftHip, user.leftKnee);
//				drawRGBBone(user.leftKnee, user.leftFoot);
//				
//				drawRGBBone(user.torso, user.rightHip);
//				drawRGBBone(user.rightHip, user.rightKnee);
//				drawRGBBone(user.rightKnee, user.rightFoot);
				
				//画出人物身上的关节
				for each(var joint:SkeletonJoint in user.skeletonJoints) {
//					rgbSkeletonContainer.graphics.lineStyle(2, 0xFF0000);
//					rgbSkeletonContainer.graphics.beginFill(0xFF0000);
//					rgbSkeletonContainer.graphics.drawCircle(joint.position.rgb.x, joint.position.rgb.y, 5);
//					rgbSkeletonContainer.graphics.endFill();
//					createBall(changPointToLocalVideo(joint.position.rgb.x,joint.position.rgb.y));
					
				}
			}
			
	
		}
		
		private var _ballGroup : Array = [];
		private function createBall(v3d : Vector3D) : Mesh
		{
			var mat : ColorMaterial = new ColorMaterial(0xFF0000);
			var gem : SphereGeometry = new SphereGeometry(10);
			
			var ball : Mesh = new Mesh(gem,mat);
			ball.x = v3d.x;
			ball.y = v3d.y;
			ball.z = v3d.z;
			_ballGroup.push(ball);
			_videoMesh.addChild(ball);
			return ball;
		}
		
		/**
		 *画出人物身上的骨头 
		 * @param from
		 * @param to
		 * 
		 */	
		private function drawRGBBone(from:SkeletonJoint, to:SkeletonJoint):void {
			rgbSkeletonContainer.graphics.lineStyle(3, 0xFF0000);
			rgbSkeletonContainer.graphics.moveTo(from.position.rgb.x, from.position.rgb.y);
			rgbSkeletonContainer.graphics.lineTo(to.position.rgb.x, to.position.rgb.y);
			rgbSkeletonContainer.graphics.lineStyle(0);
		}
		
		override protected function stopDemoImplementation():void {
			removeEventListener(Event.ENTER_FRAME, onEnterFrameHandler);
			if (device != null) {
				device.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				device.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
				device.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, onRenderVideoHandler);
				device.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler);
				device.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler);
				device.stop();
			}
			if (player != null) {
				player.removeEventListener(DeviceEvent.STARTED, kinectStartedHandler);
				player.removeEventListener(DeviceEvent.STOPPED, kinectStoppedHandler);
				player.removeEventListener(CameraImageEvent.RGB_IMAGE_UPDATE, onRenderVideoHandler);
				player.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler);
				player.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler);
				player.stop();
			}
			view.dispose();
		}
		
		override protected function layout():void {
			if (view != null) {
				view.width = explicitWidth;
				view.height = explicitHeight;
			}
		}
	}
}