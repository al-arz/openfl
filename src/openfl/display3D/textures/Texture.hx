package openfl.display3D.textures; #if !flash


import haxe.Timer;
import lime.graphics.opengl.GL;
import lime.utils.ArrayBufferView;
import openfl._internal.renderer.opengl.GLTexture;
import openfl._internal.renderer.opengl.GLUtils;
import openfl._internal.renderer.SamplerState;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.utils.ByteArray;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(openfl.display3D.Context3D)
@:access(openfl.display.Stage)


@:final class Texture extends TextureBase {
	
	
	@:noCompletion private static var __lowMemoryMode:Bool = false;
	
	
	@:noCompletion private function new (context:Context3D, width:Int, height:Int, format:Context3DTextureFormat, optimizeForRenderToTexture:Bool, streamingLevels:Int) {
		
		super (context);
		
		__width = width;
		__height = height;
		//__format = format;
		__optimizeForRenderToTexture = optimizeForRenderToTexture;
		__streamingLevels = streamingLevels;
		
		GLTexture.create (this);
		
	}
	
	
	public function uploadCompressedTextureFromByteArray (data:ByteArray, byteArrayOffset:UInt, async:Bool = false):Void {
		
		if (!async) {
			
			GLTexture.uploadCompressedTextureFromByteArray (this, data, byteArrayOffset);
			
		} else {
			
			Timer.delay (function () {
				
				GLTexture.uploadCompressedTextureFromByteArray (this, data, byteArrayOffset);
				dispatchEvent (new Event (Event.TEXTURE_READY));
				
			}, 1);
			
		}
		
	}
	
	
	public function uploadFromBitmapData (source:BitmapData, miplevel:UInt = 0, generateMipmap:Bool = false):Void {
		
		GLTexture.uploadFromBitmapData (this, source, miplevel, generateMipmap);
		
	}
	
	
	public function uploadFromByteArray (data:ByteArray, byteArrayOffset:UInt, miplevel:UInt = 0):Void {
		
		GLTexture.uploadFromByteArray (this, data, byteArrayOffset, miplevel);
		
	}
	
	
	public function uploadFromTypedArray (data:ArrayBufferView, miplevel:UInt = 0):Void {
		
		GLTexture.uploadFromTypedArray (this, data, miplevel);
		
	}
	
	
	@:noCompletion private override function __setSamplerState (state:SamplerState):Bool {
		
		if (super.__setSamplerState (state)) {
			
			var gl = __context.__gl;
			
			if (state.minFilter != gl.NEAREST && state.minFilter != gl.LINEAR && !__samplerState.mipmapGenerated) {
				
				gl.generateMipmap (gl.TEXTURE_2D);
				// GLUtils.CheckGLError ();
				
				__samplerState.mipmapGenerated = true;
				
			}
			
			if (state.maxAniso != 0.0) {
				
				gl.texParameterf (gl.TEXTURE_2D, Context3D.TEXTURE_MAX_ANISOTROPY_EXT, state.maxAniso);
				// GLUtils.CheckGLError ();
				
			}
			
			return true;
			
		}
		
		return false;
		
	}
	
	
}


#else
typedef Texture = flash.display3D.textures.Texture;
#end