#!/usr/bin/env python3

import argparse
import json
import re
from html import escape, unescape
from pathlib import Path


ALLOWED_TYPES = {"single", "multi", "text", "textarea"}
ALLOWED_PREVIEW_TYPES = {"html", "svg"}
BLOCKED_MARKUP = re.compile(
    r"</?(?:script|iframe|object|embed|link|meta|style|foreignObject|animate|set|use"
    r"|form|button|input|select|textarea|a|img|video|audio|canvas|dialog|details|summary)\b"
    r"|\b(?:on[a-z]+|href|src|xlink:href|action|formaction|poster|srcset"
    r"|contenteditable|tabindex|autofocus)\s*="
    r"|url\s*\(|javascript\s*:|data\s*:|https?\s*:|(?<!:)//",
    re.IGNORECASE,
)
ID_PATTERN = re.compile(r"^[A-Za-z][A-Za-z0-9_-]*$")
LOCALE_TAG_PATTERN = re.compile(r"^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$")
REQUIRED_UI_KEYS = {
    "actionsAria",
    "additionalDetailsOptional",
    "additionalPrefix",
    "copied",
    "copyFailed",
    "copyResults",
    "defaultSubmitTitle",
    "direction",
    "htmlLang",
    "multiHint",
    "noneApply",
    "notAnswered",
    "other",
    "otherPlaceholder",
    "recommended",
    "requiredQuestion",
    "requiredStatus",
    "separator",
    "submit",
    "submitted",
    "submitFailed",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate_config(config):
    require(isinstance(config, dict), "Config must be a JSON object")
    require(isinstance(config.get("batchId"), str) and config["batchId"].strip(), "batchId is required")
    require(config.get("locale") is None or isinstance(config["locale"], str), "locale must be a string")
    questions = config.get("questions")
    require(isinstance(questions, list) and questions, "questions must be a non-empty array")

    seen_ids = set()
    for index, question in enumerate(questions):
        prefix = f"questions[{index}]"
        require(isinstance(question, dict), f"{prefix} must be an object")
        question_id = question.get("id")
        require(isinstance(question_id, str) and ID_PATTERN.fullmatch(question_id), f"{prefix}.id is invalid")
        require(question_id not in seen_ids, f"Duplicate question id: {question_id}")
        seen_ids.add(question_id)
        question_type = question.get("type")
        require(question_type in ALLOWED_TYPES, f"{prefix}.type must be one of {sorted(ALLOWED_TYPES)}")
        require(isinstance(question.get("label"), str) and question["label"].strip(), f"{prefix}.label is required")

        if question_type in {"single", "multi"}:
            options = question.get("options")
            require(isinstance(options, list) and len(options) >= 2, f"{prefix}.options needs at least two items")
            option_values = set()
            for option_index, option in enumerate(options):
                option_prefix = f"{prefix}.options[{option_index}]"
                require(isinstance(option, dict), f"{option_prefix} must be an object")
                value = option.get("value")
                require(isinstance(value, str) and value and value != "__other__", f"{option_prefix}.value is invalid")
                require(value not in option_values, f"Duplicate option value in {question_id}: {value}")
                option_values.add(value)
                require(isinstance(option.get("label"), str) and option["label"].strip(), f"{option_prefix}.label is required")
                preview = option.get("preview")
                if preview is not None:
                    require(isinstance(preview, dict), f"{option_prefix}.preview must be an object")
                    require(preview.get("type") in ALLOWED_PREVIEW_TYPES, f"{option_prefix}.preview.type is invalid")
                    content = preview.get("content")
                    require(isinstance(content, str) and content.strip(), f"{option_prefix}.preview.content is required")
                    require(
                        not BLOCKED_MARKUP.search(unescape(content)),
                        f"Unsafe markup in {option_prefix}.preview.content",
                    )
        else:
            require("options" not in question, f"{prefix}.options is only valid for choice questions")


def safe_json(config):
    serialized = json.dumps(config, ensure_ascii=False, separators=(",", ":"))
    return (
        serialized.replace("&", "\\u0026")
        .replace("<", "\\u003c")
        .replace(">", "\\u003e")
        .replace("\u2028", "\\u2028")
        .replace("\u2029", "\\u2029")
    )


def normalize_locale(value):
    locale = str(value or "").strip().replace("_", "-") or "en"
    lowered = locale.lower()
    if lowered in {"zh", "zh-cn", "zh-hans", "zh-hans-cn"}:
        return "zh-Hans"
    language = lowered.split("-", 1)[0]
    if language in {"en", "hi", "es", "ar"}:
        return language
    return locale


def load_locales(path):
    locales = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(locales, dict) and locales, "assets/locales.json must contain locale objects")
    for locale, ui in locales.items():
        require(isinstance(ui, dict), f"Locale {locale} must be an object")
        missing = REQUIRED_UI_KEYS.difference(ui)
        require(not missing, f"Locale {locale} is missing keys: {sorted(missing)}")
        for key in REQUIRED_UI_KEYS:
            require(isinstance(ui[key], str) and ui[key].strip(), f"Locale {locale}.{key} must be a non-empty string")
        require(LOCALE_TAG_PATTERN.fullmatch(ui["htmlLang"]), f"Locale {locale}.htmlLang is invalid")
        require(ui["direction"] in {"ltr", "rtl"}, f"Locale {locale}.direction must be ltr or rtl")
    return locales


def render(config_path, output_path, standalone, locale=None):
    skill_dir = Path(__file__).resolve().parent.parent
    template = (skill_dir / "assets" / "ask-template.html").read_text(encoding="utf-8")
    config = json.loads(config_path.read_text(encoding="utf-8"))
    validate_config(config)
    locales = load_locales(skill_dir / "assets" / "locales.json")
    locale_code = normalize_locale(locale or config.get("locale") or "en")
    require(locale_code in locales, f"Unsupported locale: {locale_code}. Use one of: {', '.join(locales)}")
    ui = locales[locale_code]
    runtime_ui = {key: value for key, value in ui.items() if key not in {"languageName", "htmlLang", "direction"}}
    require(template.count("__ASK_CONFIG__") == 1, "Template must contain one __ASK_CONFIG__ placeholder")
    require(template.count("__ASK_UI__") == 1, "Template must contain one __ASK_UI__ placeholder")
    require(template.count("__ASK_ROOT_ID__") == 2, "Template must contain two __ASK_ROOT_ID__ placeholders")
    require(template.count("__ASK_LOCALE__") == 1, "Template must contain one __ASK_LOCALE__ placeholder")
    require(template.count("__ASK_DIR__") == 1, "Template must contain one __ASK_DIR__ placeholder")
    require(template.count("__ASK_CAN_SEND__") == 1, "Template must contain one __ASK_CAN_SEND__ placeholder")
    root_suffix = re.sub(r"[^A-Za-z0-9_-]+", "-", config["batchId"]).strip("-") or "batch"
    root_id = f"ask-{root_suffix}"
    fragment = (
        template.replace("__ASK_CONFIG__", safe_json(config))
        .replace("__ASK_UI__", safe_json(runtime_ui))
        .replace("__ASK_ROOT_ID__", root_id)
        .replace("__ASK_LOCALE__", escape(ui["htmlLang"], quote=True))
        .replace("__ASK_DIR__", escape(ui["direction"], quote=True))
        .replace("__ASK_CAN_SEND__", "false" if standalone else "true")
    )

    if standalone:
        css = (skill_dir / "assets" / "standalone.css").read_text(encoding="utf-8")
        title = str(config.get("title") or "Ask")
        document = (
            f"<!doctype html>\n<html lang=\"{escape(ui['htmlLang'], quote=True)}\" "
            f"dir=\"{escape(ui['direction'], quote=True)}\">\n<head>\n"
            "<meta charset=\"utf-8\">\n"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
            f"<title>{escape(title)}</title>\n<style>\n{css}\n</style>\n</head>\n<body>\n"
            f"{fragment}\n</body>\n</html>\n"
        )
    else:
        document = fragment

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(document, encoding="utf-8")
    output_path.chmod(0o600)


def main():
    parser = argparse.ArgumentParser(description="Render an Ask questionnaire from JSON")
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--locale", help="UI locale; CLI value overrides config.locale")
    parser.add_argument("--standalone", action="store_true")
    args = parser.parse_args()
    render(args.config, args.output, args.standalone, args.locale)


if __name__ == "__main__":
    main()
