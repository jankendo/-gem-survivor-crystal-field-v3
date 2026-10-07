"""Read actual export/app metadata; do not infer builds from a release label."""
import pathlib, re
ROOT = pathlib.Path(__file__).resolve().parent.parent

def export_metadata(platform, preset_path=None, project_path=None):
    text = pathlib.Path(preset_path or ROOT/'export_presets.cfg').read_text()
    blocks = re.split(r'(?m)^\[([^\]]+)\]\s*$', text)
    sections = dict(zip(blocks[1::2], blocks[2::2]))
    def value(section, key):
        match = re.search(r'(?m)^'+re.escape(key)+r'="([^"\n]+)"$', section)
        assert match, 'missing export metadata: '+key
        return match.group(1)
    target = 'iOS' if platform == 'ios' else 'Windows Desktop'
    presets = [key for key, section in sections.items() if re.fullmatch(r'preset\.\d+',key) and value(section,'platform') == target]
    assert len(presets) == 1, 'one export preset required'
    options = sections[presets[0]+'.options']
    project = pathlib.Path(project_path or ROOT/'project.godot').read_text()
    return {'app_version':value(project,'config/version'),
            'app_build':value(options,'application/version' if platform == 'ios' else 'application/file_version')}
