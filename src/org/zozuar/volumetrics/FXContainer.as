package volumetrix {
    import ;

    public class FXContainer extends Sprite {
		protected var _object:DisplayObject;
		protected var _emissionMap:IBitmapDrawable;
		protected var _src:BitmapData;
		protected var _dst:BitmapData;

        public function FXContainer(object:DisplayObject, emissionMap:IBitmapDrawable, width:Number, height:Number, buffSize:int = 0x10000) {
			_object = object;
			_emissionMap = emissionMap;
			scrollRect = new Rectangle(0, 0, width, height);
        }

		protected function initBuffers(size:int):void {
			if(_src) _src.dispose();
			if(_dst) _dst.dispose();
			var aspect:Number = scrollRect.width / scrollRect.height;
			var h:int = Math.max(1, Math.sqrt(size/aspect));
			var w:int = Math.max(1, h*aspect);
		}
    }
}