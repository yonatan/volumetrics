package org.zozuar.volumetrics {
    import flash.display.*;
    import flash.events.*;
    import flash.filters.*;
    import flash.geom.*;

    /**
    * The EffectContainer class creates a volumetric light effect (also known as crepuscular or "god" rays).
    * This is done in 2D with some bitmap processing of an emission object, and optionally an occlusion object.
    */
    public class EffectContainer extends Sprite {
        /**
        * When true a blur filter is applied to the final effect bitmap (can help when colorIntegrity == true).
        */
        public var blur:Boolean = false;
        /**
        * Selects rendering method; when set to true colors won't be distorted and performance will be
        * a little worse. Also, this might make the final output appear grainier.
        */
        public var colorIntegrity:Boolean = false;
        /**
        * Light intensity.
        */
        public var intensity:Number = 4;
        /**
        * Number of passes applied to buffer. Lower numbers mean lower quality but better performance,
        * anything above 8 is probably overkill.
        */
        public var passes:uint = 6;
        /**
        * Set this to one of the StageQuality constants to use this quality level when drawing bitmaps, or to
        * null to use the current stage quality. Mileage may vary on different platforms and player versions.
        * I think it should only be used when stage.quality is LOW (set this to BEST to get reasonable results).
        */
        public var rasterQuality:String = null;
        /**
        * Final scale of emission. Should always be more than 1.
        */
        public var scale:Number = 2;
        /**
        * Smooth scaling of the effect's final output bitmap.
        */
        public var smoothing:Boolean = true;
        /**
        * Light source x.
        * @default viewport center (set in constructor).
        */
        public var srcX:Number;
        /**
        * Light source y.
        * @default viewport center (set in constructor).
        */
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
        protected var _bufferRect:Rectangle = new Rectangle;
        protected var _viewportWidth:uint;
        protected var _viewportHeight:uint;
        protected var _mtx:Matrix = new Matrix;
        protected var _zero:Point = new Point;

        /**
        * Creates a new effect container.
        *
        * @param width Viewport width in pixels.
        * @param height Viewport height in pixels.
        * @param emission A DisplayObject to which the effect will be applied. This object will be
        * added as a child of the container. When applying the effect the object's filters and color
        * transform are ignored, if you want to use filters or a color transform put your content in
        * another object and addChild it to this one instead.
        * @param occlusion An optional occlusion object, handled the same way as the emission object.
        */
        public function EffectContainer(width:uint, height:uint, emission:DisplayObject, occlusion:DisplayObject = null) {
            if(!emission) throw(new Error("emission DisplayObject must not be null."));
            addChild(_emission = emission);
            if(occlusion) addChild(_occlusion = occlusion);
            setViewportSize(width, height);
            _lightBmp.blendMode = BlendMode.ADD;
            addChild(_lightBmp);
            srcX = width / 2;
            srcY = height / 2;
        }

        /**
        * Sets the container's size. This method recreates internal buffers (slow), do not call this on
        * every frame.
        *
        * @param width Viewport width in pixels
        * @param height Viewport height in pixels
        */
        public function setViewportSize(width:uint, height:uint):void {
            _viewportWidth = width;
            _viewportHeight = height;
            scrollRect = new Rectangle(0, 0, width, height);
            _updateBuffers();
        }

        /**
        * Sets the approximate size (in pixels) of the effect's internal buffers. Smaller number means lower
        * quality and better performance. This method recreates internal buffers (slow), do not call this on
        * every frame.
        *
        * @param size Buffer size in pixels
        */
        public function setBufferSize(size:uint):void {
            _bufferSize = size;
            _updateBuffers();
        }

        protected function _updateBuffers():void {
            var aspect:Number = _viewportWidth / _viewportHeight;
            _bufferRect.height = int(Math.max(1, Math.sqrt(_bufferSize / aspect)));
            _bufferRect.width  = int(Math.max(1, _bufferRect.height * aspect));
            dispose();
            _baseBmd           = new BitmapData(_bufferRect.width, _bufferRect.height, false, 0);
            _bufferBmd         = new BitmapData(_bufferRect.width, _bufferRect.height, false, 0);
            _occlusionLoResBmd = new BitmapData(_bufferRect.width, _bufferRect.height, true, 0);
            _occlusionLoResBmp = new Bitmap(_occlusionLoResBmd);
        }

        /**
        * Render a single frame.
        *
        * @param e In case you want to make this an event listener.
        */
        public function render(e:Event = null):void {
            if(!(_lightBmp.visible = intensity > 0)) return;
            var savedQuality:String = stage.quality;
            if(rasterQuality) stage.quality = rasterQuality;
            var mul:Number = colorIntegrity ? intensity : intensity/(1<<passes);
            _ct.redMultiplier = _ct.greenMultiplier = _ct.blueMultiplier = mul;
            _drawLoResEmission();
            if(_occlusion) _eraseLoResOcclusion();
            if(rasterQuality) stage.quality = savedQuality;
            var s:Number = 1 + (scale-1) / (1 << passes);
            var tx:Number = srcX/_viewportWidth*_bufferRect.width;
            var ty:Number = srcY/_viewportHeight*_bufferRect.height;
            _mtx.identity();
            _mtx.translate(-tx, -ty);
            _mtx.scale(s, s);
            _mtx.translate(tx, ty);
            _applyEffect(_baseBmd, _bufferRect, _bufferBmd, _mtx, passes);
            _lightBmp.bitmapData = _baseBmd;
            _lightBmp.width = _viewportWidth;
            _lightBmp.height = _viewportHeight;
            _lightBmp.smoothing = smoothing;
        }

        /**
        * Draws a scaled-down emission on _baseBmd.
        */
        protected function _drawLoResEmission():void {
            _copyMatrix(_emission.transform.matrix, _mtx);
            _mtx.scale(_bufferRect.width / _viewportWidth, _bufferRect.height / _viewportHeight);
            _baseBmd.fillRect(_bufferRect, 0);
            _baseBmd.draw(_emission, _mtx, colorIntegrity ? null : _ct);
        }

        /**
        * Draws a scaled-down occlusion on _occlusionLoResBmd and erases it from _baseBmd.
        */
        protected function _eraseLoResOcclusion():void {
            _occlusionLoResBmd.fillRect(_bufferRect, 0);
            _copyMatrix(_occlusion.transform.matrix, _mtx);
            _mtx.scale(_bufferRect.width / _viewportWidth, _bufferRect.height / _viewportHeight);
            _occlusionLoResBmd.draw(_occlusion, _mtx);
            _baseBmd.draw(_occlusionLoResBmp, null, null, BlendMode.ERASE);
        }

        /**
        * Render the effect on every frame until stopRendering is called.
        */
        public function startRendering():void {
            addEventListener(Event.ENTER_FRAME, render);
        }

        /**
        * Stop rendering on every frame.
        */
        public function stopRendering():void {
            removeEventListener(Event.ENTER_FRAME, render);
        }

        /**
        * Low-level workhorse, applies the lighting effect to a bitmap. This function modifies the bmd and buffer
        * bitmaps and its mtx argument.
        *
        * @param bmd The BitmapData to apply the effect on.
        * @param rect BitmapData rectangle.
        * @param buffer Another BitmapData object for temporary storage. Must be the same size as bmd.
        * @param mtx Effect matrix.
        * @param passes Number of passes to make.
        */
        protected function _applyEffect(bmd:BitmapData, rect:Rectangle, buffer:BitmapData, mtx:Matrix, passes:uint):void {
            while(passes--) {
                if(colorIntegrity) bmd.colorTransform(rect, _halve);
                buffer.copyPixels(bmd, rect, _zero);
                bmd.draw(buffer, mtx, null, BlendMode.ADD, null, true);
                mtx.concat(mtx);
            }
            if(colorIntegrity) bmd.colorTransform(rect, _ct);
            if(blur) bmd.applyFilter(bmd, rect, _zero, _blurFilter);
        }

        /**
        * Dispose of all intermediate buffers. After calling this the EffectContainer object will be unusable.
        */
        public function dispose():void {
            if(_baseBmd) _baseBmd.dispose();
            if(_occlusionLoResBmd) _occlusionLoResBmd.dispose();
            if(_bufferBmd) _bufferBmd.dispose();
            _baseBmd = _occlusionLoResBmd = _bufferBmd = _lightBmp.bitmapData = null;
        }

        protected function _copyMatrix(src:Matrix, dst:Matrix):void {
            dst.a = src.a;
            dst.b = src.b;
            dst.c = src.c;
            dst.d = src.d;
            dst.tx = src.tx;
            dst.ty = src.ty;
        }
    }
}