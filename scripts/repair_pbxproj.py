#!/usr/bin/env python3
from pathlib import Path
import re

pbx = Path(__file__).resolve().parents[1] / "FocusHacker.xcodeproj/project.pbxproj"
text = pbx.read_text()

container_proxy = (
    "/* Begin PBXContainerItemProxy section */\n"
    "\t\tA0C26BD50E662473A0D934F9 /* PBXContainerItemProxy */ = {\n"
    "\t\t\tisa = PBXContainerItemProxy;\n"
    "\t\t\tcontainerPortal = 3AE03DC32E0022366C8FC725 /* Project object */;\n"
    "\t\t\tproxyType = 1;\n"
    "\t\t\tremoteGlobalIDString = 0F436C7B6C48F0A4535BCB54;\n"
    "\t\t\tremoteInfo = FocusHacker;\n"
    "\t\t};\n"
    "/* End PBXContainerItemProxy section */"
)

target_dep = (
    "/* Begin PBXTargetDependency section */\n"
    "\t\tF2AB1CA25ADEC87337B932C9 /* PBXTargetDependency */ = {\n"
    "\t\t\tisa = PBXTargetDependency;\n"
    "\t\t\ttarget = 0F436C7B6C48F0A4535BCB54 /* FocusHacker */;\n"
    "\t\t\ttargetProxy = A0C26BD50E662473A0D934F9 /* PBXContainerItemProxy */;\n"
    "\t\t};\n"
    "/* End PBXTargetDependency section */"
)

patterns = [
    (r"/\* Begin PBXContainerItemProxy section \*/.*?/\* End PBXContainerItemProxy section \*/", container_proxy),
    (r"/\* Begin PBXCopyFilesBuildPhase section \*/.*?/\* End PBXCopyFilesBuildPhase section \*/\n?", ""),
    (r"\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n\t\t\t\);\n\t\t\tsourceTree = \"<group>\";\n\t\t\};\n", "\n"),
    (
        r"\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n\t\t\t\tAC7637B4DECD3E072150EDAD.*?\n\t\t\t\);\n\t\t\tsourceTree = \"<group>\";\n\t\t\};\n",
        "\n",
    ),
    (
        r"\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildPhases = \(\n\t\t\t\t3DDE1FFF20FF01C60BD3D01E.*?\n\t\t\tproductType = \"com.apple.product-type.system-extension\";\n\t\t\};\n",
        "\n",
    ),
    (
        r"\n\t\t\tisa = PBXNativeTarget;\n\t\t\tbuildPhases = \(\n\t\t\t\t13B781D4A47CF570303928B6.*?\n\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";\n\t\t\};\n",
        "\n",
    ),
    (
        r"\t\t\tdependencies = \(\n\t\t\t\t2C41E977F9E25222D6C8D75E /\* PBXTargetDependency \*/,\n\t\t\t\);",
        "\t\t\tdependencies = (\n\t\t\t);",
    ),
    (r"\n\t\t\t\t\t30D311107FCB984AC2DAF88D = \{[^}]+\};\n", "\n"),
    (r"\n\t\t\t\t\t95B9F000E2057266F74B6957 = \{[^}]+\};\n", "\n"),
    (r"\n\t\t13B781D4A47CF570303928B6 /\* Sources \*/ = \{.*?\n\t\t\};\n", "\n"),
    (r"\n\t\t3DDE1FFF20FF01C60BD3D01E /\* Sources \*/ = \{.*?\n\t\t\};\n", "\n"),
    (r"/\* Begin PBXTargetDependency section \*/.*?/\* End PBXTargetDependency section \*/", target_dep),
]

for pat, repl in patterns:
    text = re.sub(pat, repl, text, flags=re.DOTALL)

for bid in [
    "6B430F88F00D23FAE81553B2",
    "7EAB2CA65D0DBA91CECB496B",
    "9E430C6487436B75C0F915A5",
    "C7C72599F5509E48EB574E48",
]:
    text = re.sub(
        rf"\n\t\t{bid} /\* (?:Debug|Release) \*/ = \{{.*?\n\t\t\}};\n",
        "\n",
        text,
        flags=re.DOTALL,
    )

text = re.sub(
    r"\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = \(\n\t\t\t\t7EAB2CA65D0DBA91CECB496B.*?\n\t\t\tdefaultConfigurationName = Debug;\n\t\t\};\n",
    "\n",
    text,
    flags=re.DOTALL,
)
text = re.sub(
    r"\n\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = \(\n\t\t\t\t6B430F88F00D23FAE81553B2.*?\n\t\t\tdefaultConfigurationName = Debug;\n\t\t\};\n",
    "\n",
    text,
    flags=re.DOTALL,
)

pbx.write_text(text)
print("repaired")
