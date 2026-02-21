/**
 * RLM Workflow Plugin for OpenCode
 * 
 * Provides native skill discovery and loading for the RLM workflow system.
 * 
 * Installation:
 * 1. Clone rlm-workflow to ~/.config/opencode/skills/rlm-workflow/
 * 2. Enable plugin in OpenCode settings
 * 3. Restart OpenCode
 */

import { existsSync, readFileSync, readdirSync, statSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Plugin metadata
const PLUGIN_ID = 'rlm-workflow';
const PLUGIN_VERSION = '2.0.0';
const PLUGIN_NAME = 'RLM Workflow';
const PLUGIN_DESCRIPTION = 'Recursive Language Models workflow with strict phase gates, TDD discipline, and systematic debugging';

/**
 * Extract YAML frontmatter from a skill file
 * @param {string} filePath - Path to SKILL.md file
 * @returns {{name: string, description: string, content: string}}
 */
function extractSkillInfo(filePath) {
  try {
    const content = readFileSync(filePath, 'utf8');
    const lines = content.split('\n');
    
    let inFrontmatter = false;
    let frontmatterEnd = false;
    let name = '';
    let description = '';
    let frontmatterLines = [];
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      if (line.trim() === '---') {
        if (!inFrontmatter) {
          inFrontmatter = true;
          continue;
        } else {
          frontmatterEnd = true;
          break;
        }
      }
      
      if (inFrontmatter && !frontmatterEnd) {
        frontmatterLines.push(line);
        const match = line.match(/^(\w+):\s*(.*)$/);
        if (match) {
          const [, key, value] = match;
          if (key === 'name') name = value.trim();
          if (key === 'description') description = value.trim();
        }
      }
    }
    
    // Return content without frontmatter
    const contentStart = frontmatterEnd ? lines.indexOf('---', 1) + 1 : 0;
    const bodyContent = lines.slice(contentStart).join('\n').trim();
    
    return { name, description, content: bodyContent, fullContent: content };
  } catch (error) {
    console.error(`Error reading skill file ${filePath}:`, error);
    return { name: '', description: '', content: '', fullContent: '' };
  }
}

/**
 * Find all skills in the rlm-workflow directory
 * @param {string} skillsDir - Skills directory path
 * @returns {Array<{id: string, name: string, description: string, content: string}>}
 */
function findSkills(skillsDir) {
  const skills = [];
  
  // Main rlm-workflow skill
  const mainSkillPath = join(skillsDir, 'SKILL.md');
  if (existsSync(mainSkillPath)) {
    const info = extractSkillInfo(mainSkillPath);
    skills.push({
      id: 'rlm-workflow',
      name: info.name || 'rlm-workflow',
      description: info.description || 'Execute RLM workflow end-to-end',
      content: info.fullContent,
      source: 'rlm-workflow'
    });
  }
  
  // Sub-skills
  const subSkillDirs = ['rlm-tdd', 'rlm-debugging'];
  for (const dir of subSkillDirs) {
    const skillPath = join(skillsDir, 'skills', dir, 'SKILL.md');
    if (existsSync(skillPath)) {
      const info = extractSkillInfo(skillPath);
      skills.push({
        id: info.name || dir,
        name: info.name || dir,
        description: info.description || `${dir} skill`,
        content: info.fullContent,
        source: 'rlm-workflow'
      });
    }
  }
  
  return skills;
}

/**
 * Get bootstrap content for session initialization
 * @param {string} skillsDir - Skills directory path
 * @returns {string}
 */
function getBootstrapContent(skillsDir) {
  const skills = findSkills(skillsDir);
  
  let bootstrap = `# RLM Workflow for OpenCode

You have access to the RLM (Repo-Document Workflow) system for disciplined software development.

## Available Skills

`;

  for (const skill of skills) {
    bootstrap += `- **${skill.id}**: ${skill.description}\n`;
  }

  bootstrap += `
## Quick Start

1. Create run folder:
   \`\`\`bash
   mkdir -p .codex/rlm/my-feature
   \`\`\`

2. Write requirements in \`.codex/rlm/my-feature/00-requirements.md\`

3. Invoke workflow:
   \`\`\`
   Implement requirement 'my-feature'
   \`\`\`

## Documentation

- Workflow rules: \`.agent/PLANS.md\`
- Artifact templates: \`references/artifact-template.md\`
- Rationalizations: \`references/rationalizations.md\`

---

**IMPORTANT:** When using RLM workflow skills, invoke them using the \`skill\` tool.
Follow the skill instructions exactly - violating the letter of the rules is violating the spirit of quality.
`;

  return bootstrap;
}

/**
 * OpenCode Plugin Export
 */
export default {
  id: PLUGIN_ID,
  name: PLUGIN_NAME,
  version: PLUGIN_VERSION,
  description: PLUGIN_DESCRIPTION,
  
  /**
   * Initialize the plugin
   * @param {Object} context - OpenCode context
   */
  async initialize(context) {
    console.log(`[${PLUGIN_NAME}] Initializing...`);
    
    // Determine skills directory
    const skillsDir = context.skillsDir || join(process.env.HOME || process.env.USERPROFILE, '.config/opencode/skills/rlm-workflow');
    
    if (!existsSync(skillsDir)) {
      console.warn(`[${PLUGIN_NAME}] Skills directory not found: ${skillsDir}`);
      console.warn(`[${PLUGIN_NAME}] Please install: git clone https://github.com/doubleuuser/rlm-workflow.git ${skillsDir}`);
      return;
    }
    
    // Store for later use
    context.rlmWorkflow = {
      skillsDir,
      skills: findSkills(skillsDir)
    };
    
    console.log(`[${PLUGIN_NAME}] Loaded ${context.rlmWorkflow.skills.length} skills`);
  },
  
  /**
   * Hook: Session created
   * Inject bootstrap content into system prompt
   */
  hooks: {
    'session.created': async (session, context) => {
      if (!context.rlmWorkflow?.skillsDir) return;
      
      const bootstrapContent = getBootstrapContent(context.rlmWorkflow.skillsDir);
      
      // Inject into system prompt via experimental API
      if (session.prompt) {
        await session.prompt({
          content: bootstrapContent,
          noReply: true
        });
      }
    },
    
    'session.compacted': async (session, context) => {
      // Re-inject after context compaction
      if (!context.rlmWorkflow?.skillsDir) return;
      
      const bootstrapContent = getBootstrapContent(context.rlmWorkflow.skillsDir);
      
      if (session.prompt) {
        await session.prompt({
          content: `[RLM Workflow] Context compacted. Remember: ${bootstrapContent.substring(0, 500)}...`,
          noReply: true
        });
      }
    }
  },
  
  /**
   * Custom tools provided by this plugin
   */
  tools: {
    /**
     * List available RLM skills
     */
    'rlm:list-skills': {
      description: 'List all available RLM workflow skills',
      parameters: {
        type: 'object',
        properties: {},
        required: []
      },
      handler: async (args, context) => {
        const skills = context.rlmWorkflow?.skills || [];
        return {
          skills: skills.map(s => ({
            id: s.id,
            name: s.name,
            description: s.description
          }))
        };
      }
    },
    
    /**
     * Get RLM run status
     */
    'rlm:status': {
      description: 'Check status of an RLM run',
      parameters: {
        type: 'object',
        properties: {
          runId: {
            type: 'string',
            description: 'Run ID to check (optional, defaults to most recent)'
          }
        },
        required: []
      },
      handler: async (args, context) => {
        const { runId } = args;
        const cwd = process.cwd();
        const rlmDir = join(cwd, '.codex', 'rlm');
        
        if (!existsSync(rlmDir)) {
          return { error: 'No .codex/rlm directory found. Initialize a run first.' };
        }
        
        // Find run
        let targetRun = runId;
        if (!targetRun) {
          // Find most recent
          const runs = readdirSync(rlmDir)
            .filter(f => statSync(join(rlmDir, f)).isDirectory())
            .sort()
            .reverse();
          if (runs.length === 0) {
            return { error: 'No runs found' };
          }
          targetRun = runs[0];
        }
        
        const runDir = join(rlmDir, targetRun);
        if (!existsSync(runDir)) {
          return { error: `Run not found: ${targetRun}` };
        }
        
        // Check phase files
        const phases = [
          { id: '01', file: '00-requirements.md', name: 'Requirements' },
          { id: '02', file: '01-as-is.md', name: 'AS-IS Analysis' },
          { id: '02b', file: '02b-root-cause.md', name: 'Root Cause Analysis' },
          { id: '03', file: '02-to-be-plan.md', name: 'TO-BE Plan' },
          { id: '04', file: '03-implementation-summary.md', name: 'Implementation' },
          { id: '05', file: '04-test-summary.md', name: 'Test Summary' },
          { id: '06', file: '05-manual-qa.md', name: 'Manual QA' }
        ];
        
        const phaseStatus = phases.map(phase => {
          const phasePath = join(runDir, phase.file);
          if (!existsSync(phasePath)) {
            return { ...phase, status: 'PENDING' };
          }
          
          const content = readFileSync(phasePath, 'utf8');
          const statusMatch = content.match(/Status:\s*(\w+)/);
          const status = statusMatch ? statusMatch[1] : 'DRAFT';
          
          return { ...phase, status };
        });
        
        return {
          runId: targetRun,
          phases: phaseStatus,
          currentPhase: phaseStatus.find(p => p.status === 'DRAFT') || phaseStatus.find(p => p.status === 'PENDING')
        };
      }
    }
  }
};
