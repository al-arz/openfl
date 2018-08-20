package openfl._internal.renderer.opengl;


import haxe.io.Bytes;
import lime.utils.ArrayBufferView;
import lime.utils.BytePointer;
import lime.utils.UInt8Array;
import openfl._internal.formats.atf.ATFReader;
import openfl._internal.renderer.opengl.GLUtils;
import openfl._internal.renderer.SamplerState;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display.BitmapData;
import openfl.display.OpenGLRenderer;
import openfl.errors.IllegalOperationError;
import openfl.utils.ByteArray;

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(openfl._internal.renderer.SamplerState)
@:access(openfl.display3D.textures.Texture)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.DisplayObjectRenderer)


class GLTexture {
	
	
	public static function create (texture:Texture):Void {
		
		var context = texture.__context;
		var gl = context.__gl;
		
		texture.__textureTarget = gl.TEXTURE_2D;
		
		context.__bindTexture (texture.__textureTarget, texture.__textureID);
		GLUtils.CheckGLError ();
		
		gl.texImage2D (texture.__textureTarget, 0, texture.__internalFormat, texture.__width, texture.__height, 0, texture.__format, gl.UNSIGNED_BYTE, #if (lime >= "7.0.0") null #else 0 #end);
		GLUtils.CheckGLError ();
		
		context.__bindTexture (texture.__textureTarget, null);
		
	}
	
	
	public static function uploadCompressedTextureFromByteArray (texture:Texture, data:ByteArray, byteArrayOffset:UInt):Void {
		
		var reader = new ATFReader(data, byteArrayOffset);
		var alpha = reader.readHeader (texture.__width, texture.__height, false);
		
		var context = texture.__context;
		var gl = context.__gl;
		
		context.__bindTexture (texture.__textureTarget, texture.__textureID);
		GLUtils.CheckGLError ();
		
		var hasTexture = false;
		
		reader.readTextures (function (target, level, gpuFormat, width, height, blockLength, bytes:Bytes) {
			
			#if (lime < "7.0.0") // TODO
			var format = TextureBase.__compressedTextureFormats.toTextureFormat (alpha, gpuFormat);
			if (format == 0) return;
			
			hasTexture = true;
			texture.__format = format;
			texture.__internalFormat = format;
			
			if (alpha && gpuFormat == 2) {
				
				var size = Std.int (blockLength / 2);
				
				gl.compressedTexImage2D (texture.__textureTarget, level, texture.__internalFormat, width, height, 0, size, bytes);
				GLUtils.CheckGLError ();
				
				var alphaTexture = new Texture (texture.__context, texture.__width, texture.__height, Context3DTextureFormat.COMPRESSED, texture.__optimizeForRenderToTexture, texture.__streamingLevels);
				alphaTexture.__format = format;
				alphaTexture.__internalFormat = format;
				
				context.__bindTexture (alphaTexture.__textureTarget, alphaTexture.__textureID);
				GLUtils.CheckGLError ();
				
				gl.compressedTexImage2D (alphaTexture.__textureTarget, level, alphaTexture.__internalFormat, width, height, 0, size, new BytePointer (bytes, size));
				GLUtils.CheckGLError ();
				
				texture.__alphaTexture = alphaTexture;
				
			} else {
				
				gl.compressedTexImage2D (texture.__textureTarget, level, texture.__internalFormat, width, height, 0, blockLength, bytes);
				GLUtils.CheckGLError ();
				
			}
			
			// __trackCompressedMemoryUsage (blockLength);
			#end
			
		});
		
		if (!hasTexture) {
			
			var data = new UInt8Array (texture.__width * texture.__height * 4);
			gl.texImage2D (texture.__textureTarget, 0, texture.__internalFormat, texture.__width, texture.__height, 0, texture.__format, gl.UNSIGNED_BYTE, data);
			GLUtils.CheckGLError ();
			
		}
		
		context.__bindTexture (texture.__textureTarget, null);
		GLUtils.CheckGLError ();
		
	}
	
	
	public static function uploadFromBitmapData (texture:Texture, source:BitmapData, miplevel:UInt, generateMipmap:Bool):Void {
		
		/* TODO
			if (LowMemoryMode) {
				// shrink bitmap data
				source = source.shrinkToHalfResolution();
				// shrink our dimensions for upload
				width = source.width;
				height = source.height;
			}
			*/
		
		if (source == null) return;
		
		var width = texture.__width >> miplevel;
		var height = texture.__height >> miplevel;
		
		if (width == 0 && height == 0) return;
		
		if (width == 0) width = 1;
		if (height == 0) height = 1;
		
		if (source.width != width || source.height != height) {
			
			var copy = new BitmapData (width, height, true, 0);
			copy.draw (source);
			source = copy;
			
		}
		
		var image = texture.__getImage (source);
		if (image == null) return;
		
		// TODO: Improve handling of miplevels with canvas src
		
		#if (js && html5)
		if (miplevel == 0 && image.buffer != null && image.buffer.data == null && image.buffer.src != null) {
			
			var context = texture.__context;
			var gl = context.__gl;
			
			var width = texture.__width >> miplevel;
			var height = texture.__height >> miplevel;
			
			if (width == 0 && height == 0) return;
			
			if (width == 0) width = 1;
			if (height == 0) height = 1;
			
			context.__bindTexture (texture.__textureTarget, texture.__textureID);
			GLUtils.CheckGLError ();
			
			gl.texImage2D (texture.__textureTarget, miplevel, texture.__internalFormat, texture.__format, gl.UNSIGNED_BYTE, image.buffer.src);
			GLUtils.CheckGLError ();
			
			context.__bindTexture (texture.__textureTarget, null);
			GLUtils.CheckGLError ();
			
			// var memUsage = (width * height) * 4;
			// __trackMemoryUsage (memUsage);
			return;
			
		}
		#end
		
		uploadFromTypedArray (texture, image.data, miplevel);
		
	}
	
	
	public static function uploadFromByteArray (texture:Texture, data:ByteArray, byteArrayOffset:UInt, miplevel:UInt = 0):Void {
		
		#if (js && !display)
		if (byteArrayOffset == 0) {
			
			uploadFromTypedArray (texture, @:privateAccess (data:ByteArrayData).b, miplevel);
			return;
			
		}
		#end
		
		uploadFromTypedArray (texture, new UInt8Array (data.toArrayBuffer (), byteArrayOffset), miplevel);
		
	}
	
	
	public static function uploadFromTypedArray (texture:Texture, data:ArrayBufferView, miplevel:UInt = 0):Void {
		
		if (data == null) return;
		var context = texture.__context;
		var gl = context.__gl;
		
		var width = texture.__width >> miplevel;
		var height = texture.__height >> miplevel;
		
		if (width == 0 && height == 0) return;
		
		if (width == 0) width = 1;
		if (height == 0) height = 1;
		
		context.__bindTexture (texture.__textureTarget, texture.__textureID);
		GLUtils.CheckGLError ();
		
		gl.texImage2D (texture.__textureTarget, miplevel, texture.__internalFormat, width, height, 0, texture.__format, gl.UNSIGNED_BYTE, data);
		GLUtils.CheckGLError ();
		
		context.__bindTexture (texture.__textureTarget, null);
		GLUtils.CheckGLError ();
		
		// var memUsage = (width * height) * 4;
		// __trackMemoryUsage (memUsage);
		
	}
	
	
	public static function setSamplerState (texture:Texture, state:SamplerState) {
		
		
		
	}
	
	
}