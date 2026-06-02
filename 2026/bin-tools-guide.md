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

### 部署位置

`tomcat-build-browse` 目标将应用部署到项目根目录下的 `webapps/Demo` 目录：

```
E:\work2026\aribaweb\webapps\Demo\
├── docroot/          # 静态资源文件
├── META-INF/         # 应用元数据
└── WEB-INF/          # 配置和类文件
    ├── classes/      # 编译后的 Java 类
    └── lib/          # 依赖 jar 包
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

## 八、Tomcat 部署识别机制

### 自动部署原理

Tomcat 通过 **自动部署（Auto Deploy）** 机制识别 `webapps` 目录下的应用：

```
┌─────────────────────────────────────────────────────────┐
│              Tomcat 启动流程                            │
├─────────────────────────────────────────────────────────┤
│  1. 读取 conf/server.xml                               │
│     <Host name="localhost" appBase="webapps" ...>      │
│                         ↓                              │
│  2. 扫描 webapps/ 目录                                 │
│     - 检测目录（如 Demo/）                             │
│     - 检测 WAR 文件（如 Demo.war）                      │
│                         ↓                              │
│  3. 部署应用                                           │
│     - 目录名 = 上下文路径                              │
│     - webapps/Demo → http://localhost:9080/Demo       │
│                         ↓                              │
│  4. 加载 WEB-INF/web.xml 配置                          │
└─────────────────────────────────────────────────────────┘
```

### 上下文路径映射

| 项目结构 | 访问路径 |
|---------|---------|
| `webapps/Demo/` | `http://localhost:9080/Demo` |
| `webapps/Demo/AribaWeb` | `http://localhost:9080/Demo/AribaWeb` |
| `webapps/ROOT/` | `http://localhost:9080/`（根应用） |

### 关键配置

Tomcat 默认配置（`conf/server.xml`）：

```xml
<Host name="localhost" appBase="webapps"
      unpackWARs="true" autoDeploy="true">
```

| 属性 | 说明 |
|-----|------|
| `appBase="webapps"` | 指定监控的目录 |
| `autoDeploy="true"` | 自动检测新应用 |
| `unpackWARs="true"` | 自动解压 WAR 文件 |

### 配置文件位置

项目中的 Tomcat 配置文件会被自动复制到应用专属目录：

```
${catalina.base.dir}/conf/server.xml
```

**实际路径**：`build/tomcat-bases/Demo/conf/server.xml`

### 自动配置流程

```
┌──────────────────────────────────────────────────────────┐
│              Tomcat 配置初始化流程                       │
├──────────────────────────────────────────────────────────┤
│  1. has-tomcat-env 目标                                 │
│     - 检查环境变量 CATALINA_HOME                        │
│     - 设置 catalina.home.dir                            │
│                         ↓                              │
│  2. has-tomcat 目标                                    │
│     - 如果未设置 CATALINA_HOME                          │
│     - 使用项目内置的 tomcat: ${tools.dir}/tomcat        │
│                         ↓                              │
│  3. ensure-tomcat-conf 目标                            │
│     - 从 ${catalina.home.dir}/conf 复制配置到           │
│       ${catalina.base.dir}/conf                        │
│     - 调用 update-conf-port 更新端口                    │
│                         ↓                              │
│  4. 启动 Tomcat                                        │
│     - 使用 CATALINA_BASE=${catalina.base.dir}           │
│     - 默认 appBase="webapps"                            │
└──────────────────────────────────────────────────────────┘
```

### 关键参数说明

| 参数 | 说明 | 默认值 |
|-----|------|-------|
| `catalina.base.dir` | 应用专属配置目录 | `build/tomcat-bases/${name}` |
| `catalina.home.dir` | Tomcat 安装目录 | `tools/tomcat` |
| `servlet.port` | HTTP 端口 | 9080（共享模式）|
| `tomcat.port.prefix.override` | 端口前缀覆盖 | 9（共享模式）|

### 部署路径对比

| 部署方式 | catalina.base.dir | webapps 目录 | 端口 |
|---------|------------------|-------------|------|
| 官方脚本 | 项目根目录 | `webapps/` | 9080 |
| make.ps1 | `build/tomcat-bases/Demo` | `webapps/Demo` | 8080 |

### Tomcat 来源说明

**项目中没有内置 Tomcat**，系统使用环境变量 `CATALINA_HOME` 指向的外部 Tomcat：

#### 查找顺序

```xml
<!-- 1. 首先检查环境变量 CATALINA_HOME -->
<condition property="catalina.home.dir" value="${env.CATALINA_HOME}">
    <not><equals arg1="${env.CATALINA_HOME}" arg2="NOT_SET"/></not>
</condition>

<!-- 2. 如果未设置，则尝试项目内置的 tomcat -->
<property name="local.catalina.home" location="${tools.dir}/tomcat"/>
<available file="${local.catalina.home}" property="catalina.home.dir" value="${local.catalina.home}"/>

<!-- 3. 如果都找不到，报错 -->
<fail unless="catalina.home.dir" message="CATALINA_HOME environment var must be set"/>
```

#### 当前配置

| 参数 | 值 | 说明 |
|-----|------|------|
| `catalina.home` | `C:\apache-tomcat-9.0.118` | Tomcat 安装目录 |
| `catalina.base` | `E:\work2026\aribaweb` | 应用基础目录 |

#### 目录结构映射

```
C:\apache-tomcat-9.0.118/     ← catalina.home (Tomcat 安装)
├── bin/
├── lib/
└── conf/

E:\work2026\aribaweb/          ← catalina.base (应用基础)
├── conf/                      ← 应用专属配置
├── webapps/                   ← 应用部署目录
│   └── Demo/
└── logs/                      ← 应用日志
```

#### 两种运行模式

| 模式 | catalina.base | 说明 |
|-----|--------------|------|
| **共享模式** | 项目根目录 | 所有应用共享同一个 Tomcat 实例 |
| **独立模式** | `build/tomcat-bases/${name}` | 每个应用有独立的配置和端口 |

---

## 九、故障排除

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
