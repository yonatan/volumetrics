package org.zozuar.volumetrics {
    import flash.display.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.geom.*;

    public class EffectContainer extends Sprite {
		// When true a blur filter is applied to the final effect bitmap (can help when colorIntegrity == true).
		public var blur:Boolean = false;
		// Selects rendering method; when set to true colors won't be distorted and performance will be
		// a little worse. Also, this might make the final output appear grainier.
		public var colorIntegrity:Boolean = false;
		// Light intensity.
		public var intensity:Number = 4;
		// Number of passes applied to buffer. Lower numbers mean lower quality but better performance, 
		// anything above 8 is probably overkill.
		public var passes:uint = 6;
		// Set this to one of the StageQuality constants to use this quality level when drawing bitmaps,
		// or to null to use the current stage quality. Mileage may vary on different platforms and player versions.
		// I think it should only be used when stage.quality is LOW (set this to BEST to get reasonable results).
		public var rasterQuality:String = null;
		// Final scale of emission. Should always be more than 1.
		public var scale:Number = 2;
		// Smooth scaling of the effect's final output bitmap.
		public var smoothing:Boolean = true;
		// Light source x
		public var srcX:Number;
		// Light source y
		public var srcY:Number;

		protected var _blurFilter:BlurFilter = new BlurFilter(2, 2);
		protected var _emission:DisplayObject;
		protected var _occlusion:DisplayObject;
		protected var _ct:ColorTransform = new ColorTransform;
		protected var _halve:ColorTransform = new ColorTransform(0.5, 0.5, 0.5);
		protected var _occlusionLoResBmd:BitmapData;
		protected var _occlusionLoResBmp:Bitmap;
		protected var _baseBmd:BitmapData;
		protected var _bufferBmd:BitmapData;
		protected var _lightBmp:Bitmap = new Bitmap;
		protected var _bufferSize:uint = 0x8000;
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

		// Sets the container's size (in pixels). This method recreates internal buffers (slow), do not
		// call this on every frame.
		public function setViewportSize(width:uint, height:uint):void {
			_viewportWidth = width;
			_viewportHeight = height;
			scrollRect = new Rectangle(0, 0, width, height);
			_updateBuffers();
		}

		// Sets the approximate size (in pixels) of the effect's internal buffers. Smaller number means lower
		// quality and better performance. This method recreates internal buffers (slow), do not call this on 
		// every frame.
		public function setBufferSize(size:uint):void {
			_bufferSize = size;
			_updateBuffers();
		}

		protected function _updateBuffers():void {
			var aspect:Number = _viewportWidth / _viewportHeight;
			_bufferHeight = Math.max(1, Math.sqrt(_bufferSize / aspect));
			_bufferWidth  = Math.max(1, _bufferHeight * aspect);
			dispose();
			_baseBmd           = new BitmapData(_bufferWidth, _bufferHeight, false, 0);
			_bufferBmd         = new BitmapData(_bufferWidth, _bufferHeight, false, 0);
			_occlusionLoResBmd = new BitmapData(_bufferWidth, _bufferHeight, true, 0);
			_occlusionLoResBmp = new Bitmap(_occlusionLoResBmd);
		}

		// Render a single frame.
		public function render(e:Event = null):void {
			var savedQuality:String = stage.quality;
			if(rasterQuality) stage.quality = rasterQuality;
			var m:Matrix = _emission.transform.matrix.clone();
			m.scale(_bufferWidth / _viewportWidth, _bufferHeight / _viewportHeight);
			var mul:Number = colorIntegrity ? intensity : intensity/(1<<passes);
			_ct.redMultiplier = _ct.greenMultiplier = _ct.blueMultiplier = mul;
			_baseBmd.fillRect(_baseBmd.rect, 0);
			_baseBmd.draw(_emission, m, colorIntegrity ? null : _ct);
			if(_occlusion) {
				_occlusionLoResBmd.fillRect(_occlusionLoResBmd.rect, 0);
				m = _occlusion.transform.matrix.clone();
				m.scale(_bufferWidth / _viewportWidth, _bufferHeight / _viewportHeight);
				_occlusionLoResBmd.draw(_occlusion, m);
				_baseBmd.draw(_occlusionLoResBmp, null, null, BlendMode.ERASE);
			}
			if(rasterQuality) stage.quality = savedQuality;
			var s:Number = 1 + (scale-1) / (1 << passes);
			var tx:Number = srcX/_viewportWidth*_bufferWidth;
			var ty:Number = srcY/_viewportHeight*_bufferHeight;
			m.identity();
			m.translate(-tx, -ty);
			m.scale(s, s);
			m.translate(tx, ty);
			_lightBmp.bitmapData = _applyEffect(_baseBmd, _bufferBmd, m, passes);
			_lightBmp.width = _viewportWidth;
			_lightBmp.height = _viewportHeight;
			_lightBmp.smoothing = smoothing;
		}

		// Render effect on every frame until stopRendering is called.
		public function startRendering():void {
			addEventListener(Event.ENTER_FRAME, render);
		}

		// Stop rendering on every frame.
		public function stopRendering():void {
			removeEventListener(Event.ENTER_FRAME, render);
		}

		// Low-level workhorse, applies the lighting effect to a bitmap. This function modifies the src and buffer
		// bitmaps. src and buffer must be the same size. The bitmap with final output (either src or buffer) is 
		// returned.
		protected function _applyEffect(src:BitmapData, buffer:BitmapData, mtx:Matrix, passes:uint):BitmapData {
			var tmp:BitmapData;
			while(passes--) {
				if(colorIntegrity) src.colorTransform(src.rect, _halve);
				buffer.copyPixels(src, src.rect, src.rect.topLeft);
				buffer.draw(src, mtx, null, BlendMode.ADD, null, true);
				mtx.concat(mtx);
				tmp = src; src = buffer; buffer = tmp;
			}
			if(colorIntegrity) src.colorTransform(src.rect, _ct);
			if(blur) src.applyFilter(src, src.rect, src.rect.topLeft, _blurFilter);
			return src;
		}

		// Dispose of all intermediate buffers. After calling this the EffectContainer object will be unusable.
		public function dispose():void {
			if(_baseBmd) _baseBmd.dispose();
			if(_occlusionLoResBmd) _occlusionLoResBmd.dispose();
			if(_bufferBmd) _bufferBmd.dispose();
			_baseBmd = _occlusionLoResBmd = _bufferBmd = _lightBmp.bitmapData = null;
		}
    }
}