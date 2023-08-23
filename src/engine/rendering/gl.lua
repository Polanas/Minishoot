local GL_FUNCTION_PREFIX = "gl"

local ffi = require("ffi")
local utils = require("engine/utils")

ffi.cdef([[    
    typedef int GLint;
    typedef unsigned char GLboolean;
    typedef unsigned int GLuint;
    typedef unsigned char GLubyte;
    typedef float GLfloat;
    typedef float GLclampf;
    typedef int GLsizei;
    typedef char GLchar;
    
    typedef unsigned int GLenum;
    typedef unsigned int GLbitfield;

    typedef ptrdiff_t GLintptr;
    typedef ptrdiff_t GLsizeiptr;

    typedef void (* PFNGLGENBUFFERSPROC)(GLsizei n, GLuint* buffers);
    typedef void (* PFNGLBUFFERDATAPROC)(GLenum target, GLsizeiptr size, const void* data, GLenum usage);
    typedef void (* PFNGLBUFFERSUBDATAPROC)(GLenum target, GLintptr offset, GLsizeiptr size, const void* data);
    typedef void (* PFNGLBINDBUFFERPROC)(GLenum target, GLuint buffer);

    typedef void (* PFNGLCREATEVERTEXARRAYSPROC) (GLsizei n, GLuint* arrays);
    typedef void (* PFNGLBINDVERTEXARRAYPROC) (GLuint array);
    typedef void (* PFNGLVERTEXATTRIBPOINTERPROC) (GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const void* pointer);
    typedef void (* PFNGLENABLEVERTEXATTRIBARRAYPROC) (GLuint index);

    typedef GLuint (* PFNGLCREATEPROGRAMPROC) (void);
    typedef void (* PFNGLLINKPROGRAMPROC) (GLuint program);
    typedef void (* PFNGLGETPROGRAMIVPROC) (GLuint program, GLenum pname, GLint* param);
    typedef void (* PFNGLGETACTIVEUNIFORMPROC) (GLuint program, GLuint index, GLsizei maxLength, GLsizei* length, GLint* size, GLenum* type, GLchar* name);
    typedef GLint (* PFNGLGETUNIFORMLOCATIONPROC) (GLuint program, const GLchar* name);
    typedef void (* PFNGLUSEPROGRAMPROC) (GLuint program);

    typedef void (* PFNGLUNIFORM1IVPROC) (GLint location, GLsizei count, const GLint* value);
    typedef void (* PFNGLUNIFORM1FVPROC) (GLint location, GLsizei count, const GLfloat* value);
    typedef void (* PFNGLUNIFORM2FVPROC) (GLint location, GLsizei count, const GLfloat* value);
    typedef void (* PFNGLUNIFORMMATRIX4FVPROC) (GLint location, GLsizei count, GLboolean transpose, const GLfloat* value);

    typedef GLuint (* PFNGLCREATESHADERPROC)(GLenum type);
    typedef void (* PFNGLSHADERSOURCEPROC)(GLuint shader, GLsizei count, const GLchar **string, const GLint* length);
    typedef void (* PFNGLCOMPILESHADERPROC) (GLuint shader);
    typedef void (* PFNGLATTACHSHADERPROC) (GLuint program, GLuint shader);
    typedef void (* PFNGLDELETESHADERPROC) (GLuint shader);

    typedef void (* PFNGLCREATETEXTURESPROC) (GLenum target, GLsizei n, GLuint* textures);
    typedef void (* PFNGLACTIVETEXTUREPROC) (GLenum texture);
    typedef void (* PFNGLGENERATEMIPMAPPROC) (GLenum target);

    typedef void (*GLDEBUGPROC)(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar* message, const void* userParam);
    typedef void (* PFNGLDEBUGMESSAGECALLBACKPROC) (GLDEBUGPROC callback, const void *userParam);

    void* wglGetProcAddress(const char* name);

    void glEnable(GLenum cap);
    void glDisable (GLenum cap);
    void glClear(GLbitfield mask);
    void glClearColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha);
    void glViewport(GLint x, GLint y, GLsizei width, GLsizei height);
    void glDrawElements(GLenum mode, GLsizei count, GLenum type, const void *indices);
    void glBlendFunc (GLenum sfactor, GLenum dfactor);
    GLenum glGetError (void);
    
    void glBindTexture (GLenum target, GLuint texture);
    void glTexParameteri (GLenum target, GLenum pname, GLint param);
    void glTexImage2D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const void *pixels);
    void glTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const void *pixels);
]])

local lib = ffi.load("opengl32")

local gl = {
    ONE = 1,

    ONE_MINUS_SRC_ALPHA = 0x0303,

    VERTEX_SHADER = 0x8B31,
    FRAGMENT_SHADER = 0x8B30,
    ACTIVE_UNIFORMS = 0x8B86,

    ARRAY_BUFFER = 0x8892,
    ELEMENT_ARRAY_BUFFER = 0x8893,
    STATIC_DRAW = 0x88E4,

    FLOAT = 0x1406,
    UNSIGNED_INT = 0x1405,
    UNSIGNED_BYTE = 0x1401,

    TEXTURE_2D = 0x0DE1,
    TEXTURE0 = 0x84C0,
    REPEAT = 0x2901,
    NEAREST = 0x2600,
    TEXTURE_WRAP_S = 0x2802,
    TEXTURE_WRAP_T = 0x2803,
    TEXTURE_MAG_FILTER = 0x2800,
    TEXTURE_MIN_FILTER = 0x2801,

    RGBA = 0x1908,
    BLEND = 0x0BE2,
    COLOR_BUFFER_BIT = 0x00004000,
    TRIANGLES = 0x0004
}

utils.set_c_lib_metatable(gl, lib, GL_FUNCTION_PREFIX)

local function load_function(name, type)
    local pointer = lib.wglGetProcAddress(name)
    local func = ffi.cast(type, pointer)

    return func
end

local function on_debug_callback(source, type, id, severity, length, message, user_param)
    local string = ffi.string(message, length)

    print(string)
end

function gl.load_modern_functions()
    gl.GenBuffers = load_function("glGenBuffers", "PFNGLGENBUFFERSPROC")
    gl.BindBuffer = load_function("glBindBuffer", "PFNGLBINDBUFFERPROC")
    gl.BufferData = load_function("glBufferData", "PFNGLBUFFERDATAPROC")
    gl.BufferSubData = load_function("glBufferSubData", "PFNGLBUFFERSUBDATAPROC")

    gl.CreateVertexArrays = load_function("glCreateVertexArrays",  "PFNGLCREATEVERTEXARRAYSPROC")
    gl.BindVertexArray = load_function("glBindVertexArray", "PFNGLBINDVERTEXARRAYPROC")
    gl.VertexAttribPointer = load_function("glVertexAttribPointer", "PFNGLVERTEXATTRIBPOINTERPROC")
    gl.EnableVertexAttribArray = load_function("glEnableVertexAttribArray", "PFNGLENABLEVERTEXATTRIBARRAYPROC")

    gl.CreateProgram = load_function("glCreateProgram", "PFNGLCREATEPROGRAMPROC")
    gl.LinkProgram = load_function("glLinkProgram", "PFNGLLINKPROGRAMPROC")
    gl.UseProgram = load_function("glUseProgram", "PFNGLUSEPROGRAMPROC")
    gl.GetProgramiv = load_function("glGetProgramiv", "PFNGLGETPROGRAMIVPROC")
    gl.GetActiveUniform = load_function("glGetActiveUniform", "PFNGLGETACTIVEUNIFORMPROC")
    gl.GetUniformLocation = load_function("glGetUniformLocation", "PFNGLGETUNIFORMLOCATIONPROC")

    gl.Uniform1iv = load_function("glUniform1iv", "PFNGLUNIFORM1IVPROC")
    gl.Uniform1fv = load_function("glUniform1fv", "PFNGLUNIFORM1FVPROC")
    gl.Uniform2fv = load_function("glUniform2fv", "PFNGLUNIFORM2FVPROC")
    gl.UniformMatrix4fv = load_function("glUniformMatrix4fv", "PFNGLUNIFORMMATRIX4FVPROC")

    gl.CreateShader = load_function("glCreateShader", "PFNGLCREATESHADERPROC")
    gl.ShaderSource = load_function("glShaderSource", "PFNGLSHADERSOURCEPROC")
    gl.CompileShader = load_function("glCompileShader", "PFNGLCOMPILESHADERPROC")
    gl.AttachShader = load_function("glAttachShader", "PFNGLATTACHSHADERPROC")
    gl.DeleteShader = load_function("glDeleteShader", "PFNGLDELETESHADERPROC")

    gl.CreateTextures = load_function("glCreateTextures", "PFNGLCREATETEXTURESPROC")
    gl.ActiveTexture = load_function("glActiveTexture", "PFNGLACTIVETEXTUREPROC")
    gl.GenerateMipmap = load_function("glGenerateMipmap", "PFNGLGENERATEMIPMAPPROC")

    gl.DebugMessageCallback = load_function("glDebugMessageCallback", "PFNGLDEBUGMESSAGECALLBACKPROC")

    local callback = ffi.cast("GLDEBUGPROC", on_debug_callback)
    gl.DebugMessageCallback(callback, nil)
end

gl.GLint = ffi.typeof("GLint[?]")
gl.GLuint = ffi.typeof("GLuint[?]")
gl.GLsizei=  ffi.typeof("GLsizei[?]")
gl.GLchar = ffi.typeof("GLchar[?]")
gl.GLfloat = ffi.typeof("GLfloat[?]")
gl.GLubyte = ffi.typeof("GLubyte[?]")

gl.GLcharptr = ffi.typeof("const GLchar*[?]")

gl.float_size = ffi.sizeof("GLfloat")
gl.uint_size = ffi.sizeof("GLuint")

return gl