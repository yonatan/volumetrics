package org.zozuar.volumetrics {
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*;

    /**
    * VolumetricPointLight creates a simple effect container with a gradient emission pattern.
    * The gradient's center is automatically moved to the (srcX, srcY) coordinates
    * and it's radius is adjusted to the length of the viewport's diagonal, so if you
    * set srcX and srcY to the viewport's center then only half of the gradient colors
    * will be used.
    *
    * <p>This should also perform a little better than EffectContainer.</p>
    */
    public class VolumetricPointLight extends EffectContainer {
        protected var _colors:Array;
        protected var _alphas:Array;
        protected var _ratios:Array;
        protected var _gradient:Shape = new Shape;
        protected var _gradientMtx:Matrix = new Matrix;
        protected var _gradientBmp:Bitmap = new Bitmap;
        protected var _lastSrcX:Number;
        protected var _lastSrcY:Number;
        protected var _lastIntensity:Number;
        protected var _lastColorIntegrity:Boolean = false;
        protected var _gradientLoResBmd:BitmapData;
        protected var _gradientLoResDirty:Boolean = true;

        /**
        * Creates a new effect container, with an emission created from the supplied color or gradient.
        * The constructor lets you use a shortcut syntax for creating simple single-color gradients.
        * @example The shortcut syntax:
        * <listing>new VolumetricPointLight(800, 600, occlusion, 0xc08040);</listing>
        * @example is equivalent to:
        * <listing>new VolumetricPointLight(800, 600, occlusion, [0xc08040, 0], [1, 1], [0, 255]);</listing>
        *
        * @param width Viewport width in pixels.
        * @param height Viewport height in pixels.
        * @param occlusion An occlusion object, will be overlayed above the lighting gradient and under the light effect bitmap.
        * @param colorOrGradient Either a gradient colors array, or a uint color value.
        * @param alphas Will only be used if colorOrGradient is an array. This will be passed to beginGradientFill.
        *               If not provided alphas will all be 1.
        * @param ratios Will only be used if colorOrGradient is an array. This will be passed to
        *               beginGradientFill. If colorOrGradient is an Array and ratios aren't provided default
        *               ones will be created automatically.
        */
        public function VolumetricPointLight(width:uint, height:uint, occlusion:DisplayObject, colorOrGradient:*, alphas:Array = null, ratios:Array = null) {
            if(colorOrGradient is Array) {
                _colors = colorOrGradient.concat();
                _ratios = ratios || _colors.map(function(item:*, i:int, arr:Array):int { return 0x100*i/(colorOrGradient.length+i-1) });
                _alphas = alphas || _colors.map(function(..._):Number { return 1 });
            } else {
                _colors = [colorOrGradient, 0];
                _ratios = [0, 255];
            }
            super(width, height, _gradientBmp, occlusion);
            if(!occlusion) throw(new Error("An occlusion DisplayObject must be provided."));
            if(!(colorOrGradient is Array || colorOrGradient is uint)) throw(new Error("colorOrGradient must be either an Array or a uint."));
        }

        protected function _drawGradient():void {
            var size:Number = 2 * Math.sqrt(_viewportWidth*_viewportWidth + _viewportHeight*_viewportHeight);
            _gradientMtx.createGradientBox(size, size, 0, -size/2 + srcX, -size/2 + srcY);
            _gradient.graphics.clear();
            _gradient.graphics.beginGradientFill(GradientType.RADIAL, _colors, _alphas, _ratios, _gradientMtx);
            _gradient.graphics.drawRect(0, 0, _viewportWidth, _viewportHeight);
            _gradient.graphics.endFill();
            if(_gradientBmp.bitmapData) _gradientBmp.bitmapData.dispose();
            _gradientBmp.bitmapData = new BitmapData(_viewportWidth, _viewportHeight, true, 0);
            _gradientBmp.bitmapData.draw(_gradient);
        }

        /**
        * Updates the lo-res gradient bitmap if neccesary and copies it to _baseBmd.
        */
        override protected function _drawLoResEmission():void {
            if(_gradientLoResDirty) {
                super._drawLoResEmission();
                _gradientLoResBmd.copyPixels(_baseBmd, _bufferRect, _zero);
                _gradientLoResDirty = false;
            } else {
                _baseBmd.copyPixels(_gradientLoResBmd, _bufferRect, _zero);
            }
        }

        /** @inheritDoc */
        override protected function _updateBuffers():void {
            super._updateBuffers();
            _gradientLoResBmd = new BitmapData(_bufferRect.width, _bufferRect.height, false, 0);
            _gradientLoResDirty = true;
        }

        /** @inheritDoc */
        override public function setViewportSize(width:uint, height:uint):void {
            super.setViewportSize(width, height);
            _drawGradient();
            _gradientLoResDirty = true;
        }

        /** @inheritDoc */
        override public function render(e:Event = null):void {
            var srcChanged:Boolean = _lastSrcX != srcX || _lastSrcY != srcY;
            if(srcChanged) _drawGradient();
            _gradientLoResDirty ||= srcChanged;
            _gradientLoResDirty ||= (!colorIntegrity && (_lastIntensity != intensity));
            _gradientLoResDirty ||= (_lastColorIntegrity != colorIntegrity);
            _lastSrcX = srcX;
            _lastSrcY = srcY;
            _lastIntensity = intensity;
            _lastColorIntegrity = colorIntegrity;
            super.render(e);
        }

        /** @inheritDoc */
        override public function dispose():void {
            super.dispose();
            if(_gradientLoResBmd) _gradientLoResBmd.dispose();
            _gradientLoResBmd = null;
        }
    }
}
