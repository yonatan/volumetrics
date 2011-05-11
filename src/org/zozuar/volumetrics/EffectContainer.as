package org.zozuar.volumetrics {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;

    public class EffectContainer extends Sprite {
		// Light intensity.
		public var intensity:Number = 4;
		// Number of passes applied to buffer. Lower numbers means lower quality but better performance, anything above 8 is probably overkill.
		public var passes:uint = 6;
		// Final scale of emission, higher number means wider light angle. Should always be more than 1.
		public var scale:Number = 2;
		// Smooth scaling of the effect's final output bitmap.
		public var smoothing:Boolean = true;
		// Light source x
		public var srcX:Number;
		// Light source y
		public var srcY:Number;

		protected var _emission:DisplayObject;
		protected var _occlusion:DisplayObject;
		protected var _emissionBmd:BitmapData;
		protected var _ct:ColorTransform = new ColorTransform(1/16,1/16,1/16);
		protected var _occlusionBmd:BitmapData;
		protected var _occlusionBmp:Bitmap;
		protected var _buffBmd:BitmapData;
		protected var _lightBmp:Bitmap = new Bitmap;
		protected var _bufferSize:uint = 0x10000;
		protected var _bufferWidth:uint;
		protected var _bufferHeight:uint;
		protected var _viewportWidth:uint;
		protected var _viewportHeight:uint;
		
		public function EffectContainer(width:uint, height:uint, emission:DisplayObject, occlusion:DisplayObject = null) {
			if(!emission) throw(new Error("emission DisplayObject must not be null."));
			addChild(_emission = emission);
			if(occlusion) addChild(_occlusion = occlusion);
			setViewportSize(width, height);
			_lightBmp.blendMode = BlendMode.ADD;
			addChild(_lightBmp);
		}

		// Sets the container's size (in pixels).
		public function setViewportSize(width:uint, height:uint):void {
			_viewportWidth = width;
			_viewportHeight = height;
			scrollRect = new Rectangle(0, 0, width, height);
			_updateBuffers();
		}

		// Sets the approximate size (in pixels) of the effect's internal buffers. Smaller number means lower
		// quality and better performance.
		public function setBufferSize(size:uint):void {
			_bufferSize = size;
			_updateBuffers();
		}

		protected function _updateBuffers():void {
			var aspect:Number = _viewportWidth / _viewportHeight;
			_bufferHeight = Math.max(1, Math.sqrt(_bufferSize / aspect));
			_bufferWidth  = Math.max(1, _bufferHeight * aspect);
			_bufferSize = _bufferWidth * _bufferHeight;
			dispose();
			_emissionBmd  = new BitmapData(_bufferWidth, _bufferHeight, false, 0);
			_buffBmd      = new BitmapData(_bufferWidth, _bufferHeight, false, 0);
			_occlusionBmd = new BitmapData(_bufferWidth, _bufferHeight, true, 0);
			_occlusionBmp = new Bitmap(_occlusionBmd);
		}

		// Render a single frame.
		public function render(e:Event = null):void {
			var quality:String = stage.quality;
			stage.quality = StageQuality.BEST;
			var m:Matrix = _emission.transform.matrix.clone();
			m.scale(_bufferWidth / _viewportWidth, _bufferHeight / _viewportHeight);
			var mul:Number = intensity/(1<<passes);
			_ct.redMultiplier = _ct.greenMultiplier = _ct.blueMultiplier = mul;
			_emissionBmd.fillRect(_emissionBmd.rect, 0);
			_emissionBmd.draw(_emission, m, _ct);
			if(_occlusion) {
				_occlusionBmd.fillRect(_occlusionBmd.rect, 0);
				m = _occlusion.transform.matrix.clone();
				m.scale(_bufferWidth / _viewportWidth, _bufferHeight / _viewportHeight);
				_occlusionBmd.draw(_occlusion, m);
				_emissionBmd.draw(_occlusionBmp, null, null, BlendMode.ERASE);
			}
			var sf:Number = (scale-1) / (1 << passes);
			var s:Number = 1 + sf;
			var tx:Number = -sf * _bufferWidth  * srcX / _viewportWidth;
			var ty:Number = -sf * _bufferHeight * srcY / _viewportHeight;
			m.identity();
			m.scale(s, s);
			m.translate(tx, ty);
			_lightBmp.bitmapData = applyEffect(_emissionBmd, _buffBmd, m, passes);
			_lightBmp.width = _viewportWidth;
			_lightBmp.height = _viewportHeight;
			_lightBmp.smoothing = smoothing;
			stage.quality = quality;
		}

		// Render effect on every frame until stopRendering is called.
		public function startRendering():void {
			addEventListener(Event.ENTER_FRAME, render);
		}

		// Stop rendering on every frame.
		public function stopRendering():void {
			removeEventListener(Event.ENTER_FRAME, render);
		}

		// Low-level workhorse, applies the lighting effect to a bitmap. This function modifies the src and buff
		// bitmaps. src and buff must be the same size. The bitmap with final output (either src or buff) is 
		// returned.
		public static function applyEffect(src:BitmapData, buff:BitmapData, mtx:Matrix, passes:uint):BitmapData {
			var tmp:BitmapData;
			while(passes--) {
				buff.copyPixels(src, src.rect, src.rect.topLeft);
				buff.draw(src, mtx, null, BlendMode.ADD, null, true);
				mtx.concat(mtx);
				tmp = src; src = buff; buff = tmp;
			}
			return src;
		}

		// Dispose of all intermediate buffers. After calling this the EffectContainer object will be unusable.
		public function dispose():void {
			if(_emissionBmd) _emissionBmd.dispose();
			if(_occlusionBmd) _occlusionBmd.dispose();
			if(_buffBmd) _buffBmd.dispose();
			_emissionBmd = _occlusionBmd = _buffBmd = _lightBmp.bitmapData = null;
		}
    }
}