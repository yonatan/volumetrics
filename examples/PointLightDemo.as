package {
	import flash.display.*;
	import flash.events.*;
	import org.zozuar.volumetrics.*;

	[SWF(width="800", height="600", backgroundColor="0")]
	public class PointLightDemo extends Sprite {
		private var fx:VolumetricPointLight;
		private var grid:Grid = new Grid;
		private var sun:SunIcon = new SunIcon;

		public function PointLightDemo():void {
			addEventListener(Event.ADDED_TO_STAGE, init);
			if(null != stage) init();
		}

		private function init(e:Event = null):void {
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.quality = "medium";
			stage.align = "TL";
			stage.scaleMode = "noScale";

			// Create a VolumetricPointLight object, use the grid as the occlusion object.
			fx = new VolumetricPointLight(800, 600, grid, [0xc08040, 0x4080c0, 0], [1, 1, 1], [0, 20, 30]);
			// You can also specify a single color instead of gradient params, for example:
			//   fx = new VolumetricPointLight(800, 600, grid, 0xc08040);
			// is equivalent to:
			//   fx = new VolumetricPointLight(800, 600, grid, [0xc08040, 0], [1, 1], [0, 255]);

			addChild(fx);
			// Render on every frame.
			fx.startRendering();

			// This is only required if you want your SWF to be resizeable...
			onResize(null);
			stage.addEventListener(Event.RESIZE, onResize);

			// Sun icon used to control light source position
			addChild(sun);
			sun.buttonMode = true;
			sun.addEventListener(MouseEvent.MOUSE_DOWN, function(e:Event):void { sun.startDrag(); });
			sun.addEventListener(MouseEvent.MOUSE_UP, function(e:Event):void { sun.stopDrag(); });
			addEventListener(Event.ENTER_FRAME, function(..._):void { fx.srcX = sun.x; fx.srcY = sun.y; });
		}

		private function onResize(e:Event):void {
			var w:Number = stage.stageWidth;
			var h:Number = stage.stageHeight;
			fx.setViewportSize(w, h);
			sun.x = fx.srcX = w/2;
			sun.y = fx.srcY = h/2;
			grid.x = w/2-232;
			grid.y = h/2-232;
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

/**
* Copyright k3lab ( http://wonderfl.net/user/k3lab )
* MIT License ( http://www.opensource.org/licenses/mit-license.php )
* Downloaded from: http://wonderfl.net/c/ptmi
*/

import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Point;
class Grid extends Sprite
{
    private var test:Sprite
    private var lines:Sprite;
    private  var _pont:Point
    private  var Arrays:Array;
    private  var SQ:Array;

    private var diff:Number
    private var radian:Number
    private var diffPoint:Point
    private var Reaction:uint = 175;
    private var spring:Number = 0.3
    private var friction:Number = 0.68;
    public function Grid():void {
		if (stage) init();
		else addEventListener(Event.ADDED_TO_STAGE, init);
	}
	private function init(e:Event = null):void {
		removeEventListener(Event.ADDED_TO_STAGE, init);
		// entry point
		Arrays = []
		SQ=[]
		for (var i:int = 0; i < 6; i++ ) {
			for (var j:int = 0; j < 6; j++ ) {
				var _point:Points = new Points(95 * i, 95 * j);
				Arrays.push(_point)
				var test:Sprite = addChild(new Sprite()) as Sprite;
				test.graphics.beginFill(0x101010);
				test.graphics.drawCircle(0, 0, 20);
				test.graphics.endFill();
				SQ.push(test)
			}
		}
		lines = addChild(new Sprite()) as Sprite;
		addEventListener(Event.ENTER_FRAME, enter);
	}
	private function enter(e:Event):void {
		var mousePoint:Point = new Point(mouseX, mouseY);
		var i:int;
		for each (var _point:Points in Arrays) {
			_point.update(mousePoint,  Reaction, spring, friction);
			SQ[i].x = _point.x;
			SQ[i].y = _point.y
			i++;
		}
		lines.graphics.clear();
		lines.graphics.lineStyle (20, 0x101010, 1);
		for (var n:int = 0; n < 36; n++ ) {
			lines.graphics.beginFill(0x000000,Math.min(1,distance/350))
			lines.graphics.moveTo(SQ[n].x, SQ[n].y);
			var distance:Number = Point.distance(mousePoint, new Point(SQ[n].x+47, SQ[n].y+47));
			if (n < 30) {
				lines.graphics.lineTo( SQ[(n + 6)].x, SQ[n + 6].y);
				if(n%6){
					lines.graphics.lineTo( SQ[(n + 5 )].x, SQ[n + 5].y);
					lines.graphics.lineTo( SQ[(n - 1 )].x, SQ[n - 1].y);
				}
				if(n==2||n==1){
					lines.graphics.lineTo( SQ[(n-1)].x, SQ[n - 1].y);
					lines.graphics.lineTo(SQ[n].x, SQ[n].y);
				}
			}
		}
		lines.graphics.endFill()
	}

}


import flash.geom.Point;
class Points {
    private var localX:Number;
    private var localY:Number;
    private var vx:Number = 0;
    private var vy:Number = 0;
    private var _x:Number;
    private var _y:Number;
    public function Points(x:Number, y:Number) {
        _x = localX = x;
        _y = localY = y;
    }
    public function update(mousePoint:Point, Reaction:uint, spring:Number, friction:Number):void {
        var dx:Number;
		var dy:Number;
        var distance:Number = Point.distance(mousePoint, new Point(localX, localY));
        if (distance < Reaction) {
            var diff:Number     = distance * -1 * (Reaction - distance) / Reaction;
            var radian:Number   = Math.atan2(mousePoint.y - localY, mousePoint.x - localX);
            var diffPoint:Point = Point.polar(diff, radian);
            dx = localX + diffPoint.x;
            dy = localY + diffPoint.y;
        } else{
            dx = localX;
            dy = localY;
        }
        vx += (dx - _x) * spring;
        vy += (dy - _y) * spring;
        vx *= friction;
        vy *= friction;
        _x += vx;
        _y += vy;
    }
    public function get x():Number { return _x; }
    public function get y():Number { return _y; }
}
