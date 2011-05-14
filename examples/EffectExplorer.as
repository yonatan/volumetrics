package {
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import flash.geom.*;
	import flash.filters.*;
	import org.zozuar.volumetrics.*;
	import com.bit101.components.*;
	import net.hires.debug.Stats;

	[SWF(width="800", height="600", backgroundColor="0", frameRate="100")]
	public class EffectExplorer extends Sprite {
		private var fx:EffectContainer;
		private var emission:Sprite = new Sprite;
		private var occlusion:Sprite = new Sprite;
		private var box:VBox;
		private var moveOcclusion:Boolean = false;
		private var src:SunIcon = new SunIcon;
		private var attachEmissionToSrc:Boolean = false;
		private var stats:Stats = new Stats;

		public function EffectExplorer():void {
			addEventListener(Event.ADDED_TO_STAGE, init);
			if(null != stage) init();
		}

		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			var g:Graphics;
			stage.quality = "medium";
			stage.align = "TL";
			stage.scaleMode = "noScale";

			g = emission.graphics;
			g.clear();
			g.beginGradientFill("radial",[16777215,16777215,9229823,5002433,0],[1,1,1,1,1],[0,20,30,145,255],
				new Matrix(0.2662,0.0000,0.0000,0.2662,0.0000,0.0000),"pad","rgb",0);
			g.drawCircle(0, 0, 300);
			g.endFill();

			g = occlusion.graphics;
			g.clear();
			g.beginFill(0x101010);
			for(var i:int = 0; i < 10; i++) {
				g.drawRect(-200/(i+1), -150/(i+1), 400/(i+1), 300/(i+1));
			}
			g.endFill();

			fx = new EffectContainer(800, 600, emission, occlusion);
			addChild(fx);

			// ui
			box = new VBox(this, 15, 15);
			box.opaqueBackground = 0xe0e0e0;
			new Label(box, 0, 0, "Drag sun icon to move light source");
			stepper(1, 12, fx, "passes");
			slider(0, 20, fx, "intensity");
			slider(1, 10, fx, "scale");
			checkbox(fx, "smoothing");
			checkbox(fx, "blur");
			checkbox(fx, "colorIntegrity");
			checkbox(this, "attachEmissionToSrc", "Drag emitter with light source");
			checkbox(this, "moveOcclusion");
			checkbox(emission, "visible", "emission.visible");
			checkbox(occlusion, "visible", "occlusion.visible");
			new PushButton(box, 0, 0, "Re-center", recenter);
			var sizeSlider:HUISlider = new HUISlider(box, 0, 0, "Buffer size", function(e:Event):void { 
					fx.setBufferSize(sizeSlider.value);
				});
			sizeSlider.tick = 0x400;
			sizeSlider.minimum = 0x400;
			sizeSlider.maximum = 0x20000;
			sizeSlider.value = 0x8000;

			addChild(stats);

			// light source icon
			stage.addChild(src);
			src.x = stage.stageWidth/2;
			src.y = stage.stageHeight/2;
			src.addEventListener(MouseEvent.MOUSE_DOWN, function(e:Event):void { src.startDrag(); });
			src.addEventListener(MouseEvent.MOUSE_UP, function(e:Event):void { src.stopDrag(); });

			onResize(null);
			emission.x = occlusion.x = stage.stageWidth/2;
			emission.y = occlusion.y = stage.stageHeight/2;
			stage.addEventListener(Event.RESIZE, onResize);
			addEventListener("enterFrame", frame);
		}

		private function recenter(e:Event = null):void {
			emission.x = src.x = stage.stageWidth/2;
			emission.y = src.y = stage.stageHeight/2;
		}

		private function checkbox(obj:Object, prop:String, text:String = null):CheckBox {
			var comp:CheckBox;
			function handler(e:*):void { obj[prop] = comp.selected; }
			comp = new CheckBox(box, 0, 0, text || prop, handler);
			comp.selected = obj[prop];
			return comp;
		}

		private function stepper(min:Number, max:Number, obj:Object, prop:String, text:String = null):NumericStepper {
			var hb:HBox = new HBox(box);
			var comp:NumericStepper;
			function handler(e:*):void { obj[prop] = comp.value; }
			new Label(hb, 0, 0, text || prop);
			comp = new NumericStepper(hb, 0, 0, handler);
			comp.min = min;
			comp.max = max;
			comp.value = obj[prop];
			return comp;
		}

		private function slider(min:Number, max:Number, obj:Object, prop:String, text:String = null):HUISlider {
			var comp:HUISlider;
			function handler(e:*):void { obj[prop] = comp.value; }
			comp = new HUISlider(box, 0, 0, text || prop, handler);
			comp.tick = 0.001;
			comp.minimum = min;
			comp.maximum = max;
			comp.value = obj[prop];
			return comp;
		}

		private function onResize(e:Event):void {
			var w:Number = stage.stageWidth;
			var h:Number = stage.stageHeight;
			fx.setViewportSize(w, h);
			stats.x = stage.stageWidth - stats.width - 10;
			stats.y = 10;
			occlusion.y = stage.stageHeight/2;
			recenter();
		}

		private function frame(e:*):void {
			occlusion.rotation++;
			var x:Number = stage.stageWidth/2 + 250 * Math.sin(getTimer()/1000);
			occlusion.x = moveOcclusion ? x : stage.stageWidth/2;
			fx.srcX = src.x;
			fx.srcY = src.y;
			if(attachEmissionToSrc) {
				emission.x = src.x;
				emission.y = src.y;
			}
			fx.render();
		}
	}
}

import flash.display.*;
import flash.filters.*;

class SunIcon extends Sprite {
	public function SunIcon() {
		buttonMode = true;
		graphics.beginFill(0, 0);
		graphics.drawCircle(0, 0, 14);
		graphics.endFill();
		graphics.lineStyle(1, 0xffc040);
		graphics.drawCircle(0, 0, 4);
		filters = [new GlowFilter(0, 1, 4, 4, 8)];
		for(var i:int = 0; i < 10; i++) {
			var sin:Number = Math.sin(Math.PI*2*i/10);
			var cos:Number = Math.cos(Math.PI*2*i/10);
			graphics.moveTo(sin*7, cos*7);
			graphics.lineTo(sin*12, cos*12);
		}
	}
}