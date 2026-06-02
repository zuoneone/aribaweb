# AribaWeb bin 目录工具使用指南

## 概述

`bin` 目录包含 AribaWeb 官方提供的命令行工具，用于编译、部署和运行项目。

## 工具列表

| 文件 | 类型 | 说明 |
|-----|------|------|
| `aw` | Unix Shell | Linux/Mac 版本核心命令工具 |
| `aw.bat` | Windows 批处理 | Windows 版本核心命令工具 |
| `start` | Unix Shell | Linux/Mac 版本启动脚本 |
| `start.bat` | Windows 批处理 | Windows 版本启动脚本 |
| `createProject.groovy` | Groovy 脚本 | 创建新项目 |
| `indexsource.groovy` | Groovy 脚本 | 索引源代码 |
| `localize.groovy` | Groovy 脚本 | 本地化工具 |
| `processdoc.groovy` | Groovy 脚本 | 文档处理 |
| `pushRelease.groovy` | Groovy 脚本 | 发布工具 |

---

## 一、核心工具：aw.bat

### 基本用法

```batch
cd E:\work2026\aribaweb
.\bin\aw.bat <命令> [参数]
```

### 内置命令

| 命令 | 说明 |
|-----|------|
| `help` | 显示帮助信息 |
| `create-project` | 创建新的 AribaWeb 项目 |

#### 示例

```batch
rem 显示帮助
.\bin\aw.bat help

rem 创建新项目
.\bin\aw.bat create-project MyProject
```

### 运行 Ant 命令

```batch
rem 编译所有模块
.\bin\aw.bat ant -f build.xml jars

rem 清理构建产物
.\bin\aw.bat ant -f build.xml clean

rem 编译单个模块
.\bin\aw.bat ant -f src/aribaweb/build.xml jar
```

---

## 二、启动脚本：start.bat

### 功能

一键启动 Tomcat 服务器并部署演示应用。

### 使用方法

```batch
cd E:\work2026\aribaweb\bin
start.bat
```

### 等价命令

```batch
cd E:\work2026\aribaweb
.\bin\aw.bat ant -f build.xml tomcat-build-browse
```

---

## 三、编译命令

### 1. 编译所有模块

```batch
cd E:\work2026\aribaweb
.\bin\aw.bat ant -f build.xml jars
```

### 2. 清理构建产物

```batch
cd E:\work2026\aribaweb
.\bin\aw.bat ant -f build.xml clean
```

### 3. 编译并部署演示应用

```batch
cd E:\work2026\aribaweb
.\bin\aw.bat ant -f build.xml tomcat-build-browse
```

### 4. 生产模式编译

```batch
cd E:\work2026\aribaweb
.\bin\aw.bat ant -f build.xml jars -Ddebug.off=true
```

---

## 四、部署与运行

### 开发模式（默认）

```batch
rem 启动开发模式
.\bin\aw.bat ant -f build.xml tomcat-build-browse

rem 访问地址
http://localhost:9080/Demo/AribaWeb
```

### 生产模式

```batch
rem 启动生产模式
.\bin\aw.bat ant -f build.xml tomcat-build-browse -Ddebug.off=true

rem 访问地址
http://localhost:9080/Demo/AribaWeb
```

---

## 五、环境变量

### 必需环境变量

| 变量 | 说明 | 示例值 |
|-----|------|-------|
| `JAVA_HOME` | JDK 安装路径 | `C:\Program Files\Java\jdk1.8.0_392` |
| `ANT_HOME` | Ant 安装路径 | `C:\apache-ant-1.10.17` |

### 可选环境变量

| 变量 | 说明 | 默认值 |
|-----|------|-------|
| `AW_HOME` | 项目根目录 | 自动检测 |
| `CATALINA_HOME` | Tomcat 安装路径 | 自动检测 |

---

## 六、常见任务

### 任务清单

| 任务 | 命令 |
|-----|------|
| **编译项目** | `.\bin\aw.bat ant -f build.xml jars` |
| **启动演示** | `.\bin\aw.bat ant -f build.xml tomcat-build-browse` |
| **清理构建** | `.\bin\aw.bat ant -f build.xml clean` |
| **创建项目** | `.\bin\aw.bat create-project MyApp` |
| **生产模式** | `.\bin\aw.bat ant -f build.xml tomcat-build-browse -Ddebug.off=true` |

---

## 七、与 2026 目录脚本对比

| 特性 | bin/aw.bat | 2026/make.ps1 | 2026/build-only.ps1 |
|-----|-----------|---------------|---------------------|
| 编译项目 | ✅ | ✅ | ✅ |
| 启动 Tomcat | ✅ | ✅ | ❌ |
| 生产模式 | ❌ | ✅ | ✅ |
| 资源重命名 | ❌ | ✅ | ✅ |
| 默认端口 | 9080 | 8080 | - |
| 部署目录 | webapps/Demo | build/tomcat-bases/Demo | build/tomcat-bases/Demo |

---

## 八、故障排除

### 1. Java 版本问题

```batch
rem 确保使用 JDK 1.8
set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_392
```

### 2. Ant 未找到

```batch
rem 设置 ANT_HOME
set ANT_HOME=C:\apache-ant-1.10.17
```

### 3. AW_HOME 未设置

```batch
rem 自动检测（运行 aw.bat 时自动设置）
rem 或手动设置：
set AW_HOME=E:\work2026\aribaweb
```

---

## 附录：目录结构

```
bin/
├── aw           # Linux/Mac 核心命令
├── aw.bat       # Windows 核心命令
├── start        # Linux/Mac 启动脚本
├── start.bat    # Windows 启动脚本
├── createProject.groovy
├── indexsource.groovy
├── localize.groovy
├── processdoc.groovy
└── pushRelease.groovy
```

---

**文档版本**: v1.0  
**创建日期**: 2026-06-02  
**适用版本**: AribaWeb
