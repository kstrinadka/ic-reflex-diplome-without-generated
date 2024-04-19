package ru.iaie.reflex.generator.r2c.helpers

import ru.iaie.reflex.generator.r2c.interfaces.IReflexIdentifiersHelper
import ru.iaie.reflex.generator.r2c.util.LiteralGenerationUtil
import ru.iaie.reflex.reflex.ArraySpecificationInit
import ru.iaie.reflex.reflex.GlobalVariable
import ru.iaie.reflex.reflex.ProcessVariable

import static extension ru.iaie.reflex.utils.ReflexModelUtil.*

class VariableGenerationHelper {
	IReflexIdentifiersHelper identifiersHelper

	new(IReflexIdentifiersHelper ih) {
		this.identifiersHelper = ih
	}

	def generateProcessVariableDefinition(ProcessVariable variable) {
		if (!variable.isImportedList) {
			return '''«LiteralGenerationUtil.translateType(variable.type)» «identifiersHelper.getProcessVariableId(variable.process, variable)»'''
		}
	}

	def generateGlobalVariableDefinition(GlobalVariable variable) {
		if (variable instanceof ArraySpecificationInit) {
			return '''«LiteralGenerationUtil.translateType(variable.type)» «identifiersHelper.getArrayGlobalVariableId(variable)»'''
		}

		return '''«LiteralGenerationUtil.translateType(variable.type)» «identifiersHelper.getGlobalVariableId(variable)»'''
	}
	
}