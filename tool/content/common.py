"""Fonctions partagées par les générateurs de modules de l'Académie.

Chaque module est écrit dans assets/courses/<id>.json. Les labos « fichier »
sont vérifiés par test/academy/advanced_content_test.dart : le fichier de
départ doit échouer, la solution réussir, avec l'analyseur partagé
(packages/cambuse_protocol/lib/infra_lint.dart).
"""
import json
import pathlib


def t(b): return {"type": "text", "body": b}


def code(b, c=None):
    d = {"type": "code", "body": b}
    if c:
        d["caption"] = c
    return d


def tip(b): return {"type": "tip", "body": b}
def warn(b): return {"type": "warning", "body": b}


def single(i, p, ch, a, e): return {"id": i, "type": "single", "prompt": p, "choices": ch, "answer": [a], "explanation": e}
def multi(i, p, ch, a, e): return {"id": i, "type": "multiple", "prompt": p, "choices": ch, "answer": a, "explanation": e}
def cmd(i, p, acc, e): return {"id": i, "type": "command", "prompt": p, "accepted": acc, "explanation": e}
def goal(type_, label, **kw): return {"type": type_, "label": label, **kw}
def no(rule, label): return goal("noRule", label, rule=rule)
def valid(label="Fichier valide"): return goal("valid", label)
def has(text, label): return goal("contains", label, text=text)
def hasnt(text, label): return goal("notContains", label, text=text)
def clean(label="Aucun problème bloquant"): return goal("noSeverity", label, severity="blocking")
def nowarn(label="Aucun avertissement"): return goal("noSeverity", label, severity="warning")


def lab(kind, intro, starter, goals, hint, solution):
    return {"kind": kind, "intro": intro, "starter": starter, "goals": goals, "hint": hint, "solution": solution}


def lesson(id_, title, minutes, objectives, sections, quiz, lab_=None):
    d = {"id": id_, "title": title, "minutes": minutes, "objectives": objectives, "sections": sections, "quiz": quiz}
    if lab_:
        d["lab"] = lab_
    return d


def rubric(*rows): return [{"criterion": c, "levels": list(levels)} for c, *levels in rows]


def write_module(id_, title, summary, objectives, prerequisites, lessons, project, glossary):
    short = [q["id"] for l in lessons for q in l["quiz"] if len(q["explanation"].strip()) < 20]
    assert not short, f"explications trop courtes : {short}"
    for l in lessons:
        for q in l["quiz"]:
            if q["type"] != "command":
                assert all(0 <= a < len(q["choices"]) for a in q["answer"]), q["id"]
        assert len(l["sections"]) >= 3, l["id"]
    module = {
        "id": id_, "version": 1, "title": title, "summary": summary, "objectives": objectives,
        "prerequisites": prerequisites, "lessons": lessons, "project": project,
        "glossary": [{"term": a, "definition": b} for a, b in glossary],
    }
    root = pathlib.Path(__file__).resolve().parents[2] / "assets" / "courses"
    (root / f"{id_}.json").write_text(json.dumps(module, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    labs = sum(1 for l in lessons if l.get("lab"))
    print(f"{id_} : {len(lessons)} leçons, {sum(len(l['quiz']) for l in lessons)} questions, {labs} labos")
