﻿package {	import flash.display.Shape;	import flash.display.Sprite;	import flash.events.Event;	import funnel.*;		public class ButtonTest extends Sprite {		private var gio:Gainer;				public function ButtonTest() {			// Instantiate a Gainer instance			// Gainerのインスタンスを生成する			gio = new Gainer();			// Uncomment the following lines to show results in graphics			// グラフィックで結果を見るには次の行をアンコメントする//			var circle:Shape = new Shape();//			circle.graphics.beginFill(0x000000);//			circle.graphics.drawEllipse(225, 150, 100, 100);//			circle.graphics.endFill();//			circle.visible = false;//			this.addChild(circle);			// Add an event listener for changes from OFF to ON			// ボタンがオフ→オンに変化した時に発生するイベントのリスナを設定			gio.button.addEventListener(PortEvent.RISING_EDGE, function(e:Event):void {				trace(" OFF  | [ON]");				// Uncomment the following line to show results in graphics				// グラフィックで結果を見るには次の行をアンコメントする//				circle.visible = true;				// Uncomment the following line to control the LED by thr button				// LEDをボタンでコントロールするには次の行をアンコメントする//				gio.led.value = 1;			});			// Add an event listener for changes from ON to OFF			// ボタンがオン→オフに変化した時に発生するイベントのリスナを設定			gio.button.addEventListener(PortEvent.FALLING_EDGE, function(e:Event):void {				trace("[OFF] |  ON ");				// Uncomment the following line to show results in graphics				// グラフィックで結果を見るには次の行をアンコメントする//				circle.visible = false;				// Uncomment the following line to control the LED by thr button				// LEDをボタンでコントロールするには次の行をアンコメントする//				gio.led.value = 0;			});		}	}}