local GLFW_FUNCTION_PREFIX = "glfw"

local ffi = require("ffi")

local utils = require("engine/utils")

ffi.cdef([[
    typedef struct GLFWwindow GLFWwindow;
    typedef struct GLFWmonitor GLFWmonitor;

    typedef void (* GLFWwindowsizefun)(GLFWwindow* window, int width, int height);
    typedef void (* GLFWkeyfun)(GLFWwindow* window, int key, int scancode, int action, int mods);
    typedef void (* GLFWcharfun)(GLFWwindow* window, unsigned int codepoint);
    typedef void (* GLFWmousebuttonfun)(GLFWwindow* window, int button, int action, int mods);

    int glfwInit(void);
    void glfwWindowHint(int hint, int value);
    GLFWwindow* glfwCreateWindow(int width, int height, const char* title, GLFWmonitor* monitor, GLFWwindow* share);
    void glfwMakeContextCurrent(GLFWwindow* window);

    bool glfwWindowShouldClose(GLFWwindow* window);
    void glfwSwapBuffers(GLFWwindow* window);
    void glfwPollEvents(void);
    double glfwGetTime(void);
    void glfwDestroyWindow(GLFWwindow* window);
    void glfwSetWindowShouldClose(GLFWwindow* window, int value);

    void glfwGetCursorPos(GLFWwindow* window, double* xpos, double* ypos);
    GLFWkeyfun glfwSetKeyCallback(GLFWwindow* window, GLFWkeyfun callback);
    GLFWmousebuttonfun glfwSetMouseButtonCallback(GLFWwindow* window, GLFWmousebuttonfun callback);
    GLFWcharfun glfwSetCharCallback(GLFWwindow* window, GLFWcharfun callback);
    const char* glfwGetKeyName(int key, int scancode);

    GLFWwindowsizefun glfwSetWindowSizeCallback(GLFWwindow* window, void (*func)(GLFWwindow* window, int width, int height));
    void glfwSetInputMode(GLFWwindow* window, int mode, int value);
    void glfwSetWindowSize(GLFWwindow* window, int width, int height);
    void glfwSetWindowTitle(GLFWwindow* window, const char* title);
]])

local lib = ffi.load("glfw3")

local glfw = {
    CONTEXT_VERSION_MAJOR = 0x00022002,
    CONTEXT_VERSION_MINOR = 0x00022003,
    OPENGL_PROFILE = 0x00022008,
    OPENGL_CORE_PROFILE = 0x00032001,

    CURSOR = 0x00033001,
    CURSOR_NORMAL = 0x00034001,
    CURSOR_HIDDEN = 0x00034002,

    RELEASE = 0,
    PRESS = 1,
    REPEAT = 2,

    RESIZABLE = 0x00020003
}

utils.set_c_lib_metatable(glfw, lib, GLFW_FUNCTION_PREFIX)

glfw.double = ffi.typeof("double[?]")

return glfw