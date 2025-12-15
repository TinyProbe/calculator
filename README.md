# 🧮 Zig Calculator CLI

<p align="center">
Zig 언어로 작성된 간단한 커맨드 라인 인터페이스(CLI) 기반의 수식 계산
프로그램입니다. 단일 문자열 인자를 받아 사칙연산을 처리합니다.
</p>

## ✨ Features

- **CLI 기반**: 명령줄에서 직접 수식을 입력하여 결과를 즉시 확인할 수 있습니다.
- **단일 수식 지원**: 숫자와 사칙연산(+, -, *, /)으로 구성된 수식 문자열을 하나의 인자로 전달받아 계산합니다.
- **연산 우선 순위**: 괄호('(', ')')를 이용한 연산 우선 순위를 제어할 수 있습니다.
- **외부 라이브러리 사용**: [TinyProbe/zig-libraries](https://github.com/TinyProbe/zig-libraries)를 사용하여 효율적인 문자열 처리 및 데이터 구조를 활용합니다.

## 🚀 Getting Started

### 📦 Installation & Build

이 프로젝트는 zig-libraries라는 서드파티 라이브러리에 의존합니다. 다음 단계에
따라 의존성을 추가하고 프로젝트를 빌드하세요.

#### 1. 의존성 패치

프로젝트의 루트 디렉터리에서 zig fetch 명령을 실행하여 zig-libraries를
다운로드하고 build.zig.zon 파일에 추가합니다.

```bash
zig fetch --save git+https://github.com/TinyProbe/zig-libraries
```

#### 2. 프로젝트 빌드

```bash
zig build
```

## 💡 Usage

빌드된 실행 파일에 큰따옴표로 묶인 하나의 수식 문자열을 인자로 전달하여
실행합니다.

**실행 구문**:

```bash
./zig-out/bin/Calculator "<Formula>"
```

**예시**:

```bash
# 예시 1: 정수와 연산자
./zig-out/bin/Calculator "1 + 2 * 3 - 4"
3

# 예시 2: 실수 연산 포함 (우선순위 고려)
./zig-out/bin/Calculator "1 + 2 * 3 / 1.24"
5.838709677419355
```

## 🔗 Related Links

- 사용된 라이브러리: [TinyProbe/zig-libraries](https://github.com/TinyProbe/zig-libraries)
- Zig 언어 공식 웹사이트: [ziglang](https://ziglang.org/)

## 📄 License

이 프로젝트는 MIT 라이선스를 따릅니다.
