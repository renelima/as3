package com.zehfernando.geom {
	import flash.geom.Point;
	/**
	 * @author zeh fernando
	 */
	public class Path {

		// Properties
		public var points:Vector.<Point>;

		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function Path() {
			points = new Vector.<Point>();
		}

		// ================================================================================================================
		// STATIC functions -----------------------------------------------------------------------------------------------

		public static function fromPoints(__points:Vector.<Point>):Path {
			var path:Path = new Path();
			path.points = __points.concat();
			return path;
		}

		public static function fromCoordinates(__coordinates:Vector.<Number>):Path {
			var path:Path = new Path();
			for (var i:int = 0; i < __coordinates.length; i+=2) path.points.push(new Point(__coordinates[i], __coordinates[i+1]));
			return path;
		}

		public static function fromCoordinatesArray(__coordinates:Array):Path {
			var path:Path = new Path();
			for (var i:int = 0; i < __coordinates.length; i+=2) path.points.push(new Point(__coordinates[i], __coordinates[i+1]));
			return path;
		}


		// ================================================================================================================
		// INSTANCE functions ---------------------------------------------------------------------------------------------

//		public function intersectsRect(__rect:Rectangle):Boolean {
//			// Check if a rectangle intersects OR contains this line
//
//			if (__rect.containsPoint(p1) || __rect.containsPoint(p2)) return true;
//
//			if (intersectsLine(new Line(new Point(__rect.left, __rect.top),		new Point(__rect.right, __rect.top)))) return true;
//			if (intersectsLine(new Line(new Point(__rect.left, __rect.top),		new Point(__rect.left, __rect.bottom)))) return true;
//			if (intersectsLine(new Line(new Point(__rect.left, __rect.bottom),	new Point(__rect.right, __rect.bottom)))) return true;
//			if (intersectsLine(new Line(new Point(__rect.right, __rect.top),	new Point(__rect.right, __rect.bottom)))) return true;
//
//			return false;
//		}
//
//		public function intersectsLine(__line:Line):Boolean {
//			// Check whether two lines intersects each other
//			return Boolean(intersection(__line));
//		}
//
//		public function intersection(__line:Line): Point {
//			// Returns a point containing the intersection between two lines
//			// http://keith-hair.net/blog/2008/08/04/find-intersection-point-of-two-lines-in-as3/
//			// http://www.gamedev.pastebin.com/f49a054c1
//
//			var a1:Number = p2.y - p1.y;
//			var b1:Number = p1.x - p2.x;
//			var a2:Number = __line.p2.y - __line.p1.y;
//			var b2:Number = __line.p1.x - __line.p2.x;
//
//			var denom:Number = a1 * b2 - a2 * b1;
//			if (denom == 0) return null;
//
//			var c1:Number = p2.x * p1.y - p1.x * p2.y;
//			var c2:Number = __line.p2.x * __line.p1.y - __line.p1.x * __line.p2.y;
//
//			var p:Point = new Point((b1 * c2 - b2 * c1)/denom, (a2 * c1 - a1 * c2)/denom);
//
//			//if(as_seg){
//			if (Point.distance(p, p2) > Point.distance(p1, p2)) return null;
//			if (Point.distance(p, p1) > Point.distance(p1, p2)) return null;
//			if (Point.distance(p, __line.p2) > Point.distance(__line.p1, __line.p2)) return null;
//			if (Point.distance(p, __line.p1) > Point.distance(__line.p1, __line.p2)) return null;
//			//}
//
//			return p;
//
//		}

		// ================================================================================================================
		// ACCESSOR functions ---------------------------------------------------------------------------------------------

		public function get length():Number {
			var l:Number = 0;
			for (var i:int = 0; i < points.length-1; i++) {
				l += Point.distance(points[i], points[i+1]);
			}
			return l;
		}

		public function getPosition(__position:Number):Point {
			// Returns a point in this position in the path (0 to length)
			if (__position < 0) return points[0].clone();

			var p:Number = 0;
			var l:Number;
			for (var i:int = 0; i < points.length-1; i++) {
				l = Point.distance(points[i], points[i+1]);
				if (p <= __position && p + l >= __position) {
					return Point.interpolate(points[i+1], points[i], (__position - p) / l);
				}
				p += l;
			}

			return points[points.length-1].clone();
		}

		public function simplify():void {
			// Simplify the path by removing middle points in lines that have the same angle
//			var pl:int = points.length;
			for (var i:int = 1; i < points.length-1; i++) {
				if (Math.atan2(points[i].y-points[i-1].y, points[i].x-points[i-1].x) == Math.atan2(points[i+1].y-points[i].y, points[i+1].x-points[i].x)) {
					// Same angle
					points.splice(i, 1);
					i--;
				}
			}
//			log("Path optimized; points before = " + pl + ", points after = " + points.length);
		}

		public function normalize():void {
			// Make sures all coordinates are from 0 to 1 by scaling the whole path back

			var i:int;
			var minX:Number;
			var maxX:Number;
			var minY:Number;
			var maxY:Number;

			// Read minimum and maximums
			for (i = 0; i < points.length; i++) {
				if (isNaN(minX) || points[i].x < minX) minX = points[i].x;
				if (isNaN(maxX) || points[i].x > maxX) maxX = points[i].x;
				if (isNaN(minY) || points[i].y < minY) minY = points[i].y;
				if (isNaN(maxY) || points[i].y > maxY) maxY = points[i].y;
			}

			// Apply mapped values
			var w:Number = maxX - minX;
			var h:Number = maxY - minY;
			for (i = 0; i < points.length; i++) {
				points[i].x = (points[i].x - minX) / w;
				points[i].y = (points[i].y - minY) / h;
			}
		}

		public static function getSimilarity(__path0:Path, __path1:Path):Number {
			// Return the similarity between two paths, by measuring the distance of points at the same breakpoints in the path
			// simplify() and normalize() the paths before calling this function!
			// 0 = identical
			// Higher = more different
			var numSegs:int = 80; // Number of segments to check (more = more precise, less = faster)

			var errorDrift:Number = 0;

			var l0:Number = __path0.length;
			var l1:Number = __path1.length;

			for (var i:int = 0; i <= numSegs; i++) {
				errorDrift += Point.distance(__path0.getPosition((i/numSegs) * l0), __path1.getPosition((i/numSegs) * l1));
			}
			return errorDrift / numSegs;
		}

		public function toCoordinates():Vector.<Number> {
			var ps:Vector.<Number> = new Vector.<Number>();
			for (var i:int = 0; i < points.length; i++) {
				ps.push(points[i].x);
				ps.push(points[i].y);
			}
			return ps;
		}

	}
}
