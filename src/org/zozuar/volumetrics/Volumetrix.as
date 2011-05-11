package volumetrix {
    import ;

    public class Volumetrix {

		public function update():void {
			scaledOccBmd.fillRect(scaledOccBmd.rect,0);
			scaledOccBmd.draw(occlusion, scaleDown);
			src.lock();
			dst.lock();
			src.fillRect(src.rect, 0);
			src.draw(scaledOccBmp, null, new ColorTransform(0.085,0.085,0.085));
			canvas.bitmapData = process(src);
			src.unlock();
			dst.unlock();
		}
		
		protected static function process(src:BitmapData):BitmapData {
			var dst:BitmapData = this.dst;
			mtx.identity();
			mtx.translate(-FXW/65, -FXH/65);
			mtx.scale(33/32, 33/32);
			var cnt:int = 5;
			var tmp:BitmapData;
			while(cnt--) {
				mtx.concat(mtx);
				dst.copyPixels(src, src.rect, src.rect.topLeft);
				dst.draw(src, mtx, null, "add");
				dst.applyFilter(dst, dst.rect, dst.rect.topLeft, blur);
				tmp = src;
				src = dst;
				dst = tmp;
			}
			return src;
		}
    }
}