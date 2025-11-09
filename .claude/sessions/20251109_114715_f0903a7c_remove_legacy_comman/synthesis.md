# Synthesis: Legacy Command Removal

## Executive Summary

The codebase contains a well-managed migration from v1.0 to v2.0 of the CC workflow system. Four legacy agent files have been deprecated and replaced by a unified `code-search-agent`. The main task involves cleaning up documentation references to complete the migration process.

## Integrated Analysis

### Current State
- **4 legacy agent files** in `cc/agents/` with `.legacy.md` extensions:
  - `dependency-analyzer.legacy.md`
  - `code-structure-explorer.legacy.md`
  - `test-coverage-analyzer.legacy.md`
  - `documentation-reviewer.legacy.md`
- **Documentation references** found in 4 files
- **Clear migration path** already documented

### Target State
- **Clean documentation** referencing only modern v2.0 agents
- **Removed legacy files** after proper deprecation period
- **Unified workflow** using `code-search-agent` for all code analysis tasks

## Gap Analysis

### Critical Gap 1: Documentation Consistency
**Current**: Legacy agents still referenced in multiple documentation files
**Recommended**: Update all references to point to modern `code-search-agent`

### Critical Gap 2: Workflow Clarity
**Current**: Mixed references to old parallel agent workflow
**Recommended**: Unified documentation reflecting v2.0 hybrid workflow

## Risk Assessment

### Risk Level: LOW
- **Technical Risk**: Minimal (documentation-only changes)
- **User Impact**: Low (improved clarity, reduced confusion)
- **Migration Risk**: None (legacy files properly marked)

### Mitigation Strategies
- Preserve migration notes in documentation
- Keep legacy files as reference during transition
- Update examples to use modern agents

## Recommendations

### Immediate Actions (Week 1)
1. **Update documentation references** in README.md, IMPLEMENTATION_GUIDE.md
2. **Remove legacy agent mentions** from EXPLORE_REFACTOR_PLAN.md
3. **Update CLAUDE.md** to reflect current v2.0 architecture

### Short-term Actions (Week 2)
1. **Archive legacy agent files** to separate directory
2. **Create migration guide** for users transitioning from v1.0 to v2.0
3. **Update all examples** to use `code-search-agent`

### Long-term Considerations (Month+)
1. **Complete removal** of legacy files after deprecation period
2. **User communication** about simplified workflow
3. **Documentation audit** to ensure consistency

## Questions for Planning Phase

1. **Deprecation Timeline**: How long should legacy files remain before complete removal?
2. **User Communication**: Should there be a migration announcement for existing users?
3. **File Location**: Should legacy files be archived or completely deleted?
4. **Documentation Strategy**: Should we maintain migration notes or fully remove legacy references?

## Success Metrics

- **Documentation Consistency**: 100% of references point to modern agents
- **User Clarity**: Reduced confusion about which agents to use
- **Maintainability**: Simplified codebase with single unified agent
- **Migration Success**: Users can easily transition from legacy workflow