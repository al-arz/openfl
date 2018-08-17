package openfl.display3D.textures; #if !flash


import haxe.Timer;
import lime.utils.ArrayBufferView;
import openfl._internal.renderer.opengl.GLCubeTexture;
import openfl._internal.formats.agal.SamplerState;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.utils.ByteArray;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(openfl.display3D.Context3D)
@:access(openfl.display.Stage)


@:final class CubeTexture extends TextureBase {
	
	
	@:noCompletion private var __size:Int;
	@:noCompletion private var __uploadedSides:Int;
	
	
	@:noCompletion private function new (context:Context3D, size:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int) {
		
		super (context);
		
		__size = size;
		//__format = format;
		__optimizeForRenderToTexture = optimizeForRenderToTexture;
		__streamingLevels = streamingLevels;
		
		GLCubeTexture.create (this);
		
	}
	
	
	public function uploadCompressedTextureFromByteArray (data:ByteArray, byteArrayOffset:UInt, async:Bool = false):Void {
		
		if (!async) {
			
			GLCubeTexture.uploadCompressedTextureFromByteArray (this, data, byteArrayOffset);
			
		} else {
			
			Timer.delay (function () {
				
				GLCubeTexture.uploadCompressedTextureFromByteArray (this, data, byteArrayOffset);
				dispatchEvent (new Event (Event.TEXTURE_READY));
				
			}, 1);
			
		}
		
	}
	
	
	public function uploadFromBitmapData (source:BitmapData, side:UInt, miplevel:UInt = 0, generateMipmap:Bool = false):Void {
		
		if (source == null) return;
		GLCubeTexture.uploadFromBitmapData (this, source, side, miplevel, generateMipmap);
		
	}
	
	
	public function uploadFromByteArray (data:ByteArray, byteArrayOffset:UInt, side:UInt, miplevel:UInt = 0):Void {
		
		GLCubeTexture.uploadFromByteArray (this, data, byteArrayOffset, side, miplevel);
		
	}
	
	
	public function uploadFromTypedArray (data:ArrayBufferView, side:UInt, miplevel:UInt = 0):Void {
		
		if (data == null) return;
		GLCubeTexture.uploadFromTypedArray (this, data, side, miplevel);
		
	}
	
	
	@:noCompletion private override function __setSamplerState (state:SamplerState) {
		
		GLCubeTexture.setSamplerState (this, state);
		
	}
	
	
}


#else
typedef CubeTexture = flash.display3D.textures.CubeTexture;
#end