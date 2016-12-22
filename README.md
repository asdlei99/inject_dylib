# Inject

Inject是一个注入dylib动态库并重签名的工具。仅供学习用。

### **How TO USE：**

clone工程文件并运行。

如图所示，依次选择app源文件、最终输出ipa的目录、重签名需要的profile文件、需要注入的动态库（可选）、以及重签名profile对应的证书。点击开始，等待注入并重签名成功。值得注意的是进行注入的app文件必须是已经砸壳的文件，如果自己懒的砸可以到越狱市场下载。

![](/screenshot/screenshot1.png)

注入后可以用MachOView等Mach文件浏览工具查看是否注入成功。比如我要注入到动态库叫`debug.dylib`，注入成功后用MachOView打开二进制文件，依次展开Executable-&gt;Load Commands，拖到`Load Commands`的最后可以看到`LC_LOAD_DYLIB(debug.dylib)`就说明已经注入成功。

### TODO:

1、目前只支持.app文件格式，后面将支持更多

