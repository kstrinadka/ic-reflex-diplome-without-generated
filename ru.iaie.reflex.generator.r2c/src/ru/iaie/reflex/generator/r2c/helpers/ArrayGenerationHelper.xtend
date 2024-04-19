package ru.iaie.reflex.generator.r2c.helpers

import ru.iaie.reflex.reflex.ArraySpecificationInit
import ru.iaie.reflex.reflex.Expression


// Для обработки генерации массивов
class ArrayGenerationHelper {
	
	static ReflexIdentifiersHelper identifiersHelper = new ReflexIdentifiersHelper
	static ExpressionGenerationHelper expressionGenerator = new ExpressionGenerationHelper(identifiersHelper)
	
	// тип не надо выводить, т.к. он до этого выводится
	def static getArrayRepresentation(ArraySpecificationInit array) {
		var String name = array.name 
		var int size = Integer.valueOf(array.size)
		
		if (array.values !== null && array.values.elements !== null && array.values.elements.size > 0) {
			return '''«name» [«size»] = «FOR value : array.values.elements BEFORE '[' SEPARATOR ', ' AFTER ']'»«getStringAssigmentElement(value)»«ENDFOR»'''
		}
		return '''«name» [«size»]'''
	}
	
	static def getStringAssigmentElement(Expression element) 
	'''«expressionGenerator.translateExpr(element)»'''
	
}