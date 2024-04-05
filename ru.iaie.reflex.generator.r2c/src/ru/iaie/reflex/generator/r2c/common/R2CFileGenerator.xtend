/* ==================================
 * ==== ARDUINO NANO (zyubin 2024) ===
 * ==================================
 */
 
package ru.iaie.reflex.generator.r2c.common

import static extension ru.iaie.reflex.utils.ReflexModelUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import ru.iaie.reflex.reflex.Program
import ru.iaie.reflex.reflex.PhysicalVariable
import ru.iaie.reflex.reflex.PortType
import ru.iaie.reflex.generator.r2c.interfaces.IFileGenerator
import ru.iaie.reflex.generator.r2c.interfaces.IReflexIdentifiersHelper
import ru.iaie.reflex.generator.r2c.helpers.PortGenerationHelper
import ru.iaie.reflex.generator.r2c.helpers.ConstantGenerationHelper
import ru.iaie.reflex.generator.r2c.helpers.VariableGenerationHelper
import ru.iaie.reflex.generator.r2c.helpers.ReflexIdentifiersHelper
import ru.iaie.reflex.generator.r2c.util.LiteralGenerationUtil

class R2CFileGenerator implements IFileGenerator {
	protected String C_STANDART = "99";
	protected String GENERATED_DIR_NAME = "generated"
	 
	// AST root 
	protected Program program
	protected IFileSystemAccess2 fsa
	
	IReflexIdentifiersHelper identifiersHelper
	PortGenerationHelper portGenerationHelper
	ConstantGenerationHelper constGenerationHelper
	VariableGenerationHelper varGenerationHelper

	protected static String CLOCK_CONST_NAME = "_r_CLOCK" 
	protected static String CUR_TIME_NAME = "_r_cur_time" 
	protected static String NEXT_TIME_NAME = "_r_next_act_time" 
	
	def String getRootDirName() {
		return "c-code"
	}

	new(Resource resource, IFileSystemAccess2 fsa) {
		program = resource.getProgram()
		this.fsa = fsa
		identifiersHelper = new ReflexIdentifiersHelper
		portGenerationHelper = new PortGenerationHelper(identifiersHelper)
		constGenerationHelper = new ConstantGenerationHelper(identifiersHelper)
		varGenerationHelper = new VariableGenerationHelper(identifiersHelper)
	}
	
	override prepareForGeneration() {
		for (resource : R2CResourceProvider.COMMON_RESOURCES) { // З: перезапись текстов-заготовок в директорию проекта
			fsa.generateFile('''«rootDirName»/«resource»''', class.getResourceAsStream('''/resources/«resource»'''))
		}
	}

	override generateBuildFiles() {
		var fileContent = '''
			cmake_minimum_required(VERSION 3.15)
			project(«program.name.toLowerCase»)
			
			set(CMAKE_C_STANDARD «C_STANDART»)
			set(CMAKE_C_FLAGS "-Wall")
			
			add_executable(«program.name.toLowerCase» generated/main.c generated/proc.c lib/r_lib.c usr/usr.c generated/io.c generated/platform.c)
		'''
		fsa.generateFile('''«rootDirName»/CMakeLists.txt''', fileContent)
	}

	override String generateIOFiles() {
		val inputVars = newArrayList()
		val outputVars = newArrayList()
		program.eAllOfType(PhysicalVariable).forEach [ v |
			v.mappedPortType == PortType.INPUT
				? inputVars.add(v)
				: outputVars.add(v)
		]
		return '''
		
		void input(void) {
			«FOR inPort: program.ports.filter[type == PortType.INPUT]»
				«portGenerationHelper.translateInputPortReading(inPort)»
			«ENDFOR»
		    «FOR physVar : inputVars»
		    	«portGenerationHelper.translateReadingFromInput(physVar)»
		    «ENDFOR»
		}
		
		void output(void) {
			«FOR physVar : outputVars»
				«portGenerationHelper.translateWritingToOutput(physVar)»
		    «ENDFOR»
			«FOR outPort: program.ports.filter[type == PortType.OUTPUT]»
				«portGenerationHelper.translateOutputPortWriting(outPort)»
			«ENDFOR»
		}
		'''
	}
	override String generateInput() {
		val inputVars = newArrayList()
		val outputVars = newArrayList()
		program.eAllOfType(PhysicalVariable).forEach [ v |
			v.mappedPortType == PortType.INPUT
				? inputVars.add(v)
				: outputVars.add(v)
		]
		return '''
		/*======= Generated Input ==========*/		
			«FOR inPort: program.ports.filter[type == PortType.INPUT]»
				«portGenerationHelper.translateInputPortReading(inPort)»
			«ENDFOR»
		    «FOR physVar : inputVars»
		    	«portGenerationHelper.translateReadingFromInput(physVar)»
		    «ENDFOR»
		/*======= End of Input ==========*/		
		'''
	}
	override String generateOutput() {
		val inputVars = newArrayList()
		val outputVars = newArrayList()
		program.eAllOfType(PhysicalVariable).forEach [ v |
			v.mappedPortType == PortType.INPUT
				? inputVars.add(v)
				: outputVars.add(v)
		]
		return '''
		/*======= Generated Output ==========*/		
			«FOR physVar : outputVars»
				«portGenerationHelper.translateWritingToOutput(physVar)»
		    «ENDFOR»
			«FOR outPort: program.ports.filter[type == PortType.OUTPUT]»
				«portGenerationHelper.translateOutputPortWriting(outPort)»
			«ENDFOR»
		/*======= End of Output ==========*/		
		'''
	}
	
// zyubin: создание platform.c файла, ищи "generatePlatformImplementations"
	override generatePlatformImplementations() {
		fsa.generateFile('''«rootDirName»/«GENERATED_DIR_NAME»/platform.c''', R2CResourceProvider.DUMMY_PLATFORM_IMPL)
	}

	override String generateConstantDefinitions() {
		return '''
			«generateConstants()»

			«generateEnums()»
			
			«generateClockConst()»
		'''
	}

	/*
	 * ================================================ 
	 * ==== Gen Variables:
	 * TimeVar
	 * Global and shared
	 * Ports images
	 * ================================================ 
	 */
	 override String generateVariableDefinitions() {
		return '''
«««			«generateTimeVariableDefinitions(false)» // не меняется
			«generateVariables(false)»
			«generatePorts(false)»
		'''
	}
	

	/*override String generateProcessDefinitions() {
		return '''
			«FOR process : program.processes»
			void «identifiersHelper.getProcessFuncId(process)»();
			«ENDFOR»
		''';
	}*/
	
	override String generateProcessVariables() {
		return ''' 
«««			const uint8_t START = 0;
«««			const uint8_t CONFIRMED = 253;
«««			const uint8_t ERROR = 254;
«««			const uint8_t STOP = 255;
		/* ===== process state constants ====== */
		#define START = 0;
		#define CONFIRMED = 253;
		#define ERROR = 254;
		#define STOP = 255;
		
		/* ===== process state vars ====== */
		«FOR process : program.processes»
			uint8_t _p_«process.name»_state;
		«ENDFOR»
			
		/* ===== process timer vars ====== */
		«FOR process : program.processes»
			uint32_t _p_«process.name»_time;
		«ENDFOR»
			
		/* ===== process states enumerators ====== */
		«FOR process : program.processes»
			enum _p_«process.name»_states {
			«FOR state : process.getStates()»
				«"  "»«state.name»«IF state == process.getStates().get(0)» = START«ENDIF»«IF state != process.getStates().get(process.getStates().size()-1)»,«ENDIF»
			«ENDFOR»
			}
		«ENDFOR»
		'''
	}

	override String generateProcessImplementations() {
		val processGenerators = program.processes.map[p | new ProcessGenerator(p, identifiersHelper)]
		return '''
			/*========= PROCESS IMAGES: ========*/
			«FOR gen : processGenerators»
			«gen.generate()»
			«ENDFOR»
			/*========= END OF PROCESSES ========*/
		'''
	}

	override String generateProcessInitialization() {
//		val processGenerators = program.processes.map[p | new ProcessGenerator(p, identifiersHelper)]
		return '''
			/*========= PROCESS INIT: ========*/
			«FOR process : program.processes»
				_p_«process.name»_state «IF (process.active == true)»= START;«ENDIF»«IF (process.active == false)»= STOP;«ENDIF»
			«ENDFOR»			
			/*========= END OF PROCESSES INIT========*/
		'''				
	}
	
	/*
	 * ================================================ 
	 * =================== MAIN.C =====================
	 * ================================================ 
	 */
	override generateMain() {
		val fileContent = '''
		#include <avr/io.h>
		#include <avr/interrupt.h>
		// #include "../lib/platform.h"
		#include "../lib/r_cnst.h" /* system constants */
		#include "../lib/r_main.h" /* Common constants and files */
		
		// Atmega 368p frequency
		#ifndef F_CPU
		#define F_CPU 16000000UL
		#endif
				
		INT32_U _r_cur_time;
		INT32_U _r_next_act_time;
		
		
		«generateVariableDefinitions()»
		
		«generateConstantDefinitions()»

		«generateProcessVariables()»
		
		void setup() {   /* Init */
«««			init_processes();
«««			init_time();
«««			init_io();

			«CUR_TIME_NAME» = millis();
			«NEXT_TIME_NAME» = «CUR_TIME_NAME»;
			#include "port_init.h"
			«generateProcessInitialization()»
		}

		void loop() {   /* Control algorithm */
			«CUR_TIME_NAME» = get_time();
			if («CUR_TIME_NAME» - «NEXT_TIME_NAME» >= 0) {
				// Find next activation time
				«NEXT_TIME_NAME» += «CLOCK_CONST_NAME»;
				if («NEXT_TIME_NAME» - «CUR_TIME_NAME» > _r_CLOCK) {
					«NEXT_TIME_NAME» = «CUR_TIME_NAME» + _r_CLOCK;
				}
«««				input();
				«generateInput()»
				«generateProcessImplementations()»
«««					«FOR proc : program.processes»
«««					«identifiersHelper.getProcessFuncId(proc)»(); /* Process «proc.name» */
«««					«ENDFOR»
«««					output();
				«generateOutput()»
			}
		}
		
«««		«generateIOFiles()»
		
«««		«generateProcessImplementations()»
		'''

		fsa.generateFile('''«rootDirName»/«GENERATED_DIR_NAME»/main.c''', fileContent)
	}
	
		
	def generateVariables(boolean externDef) {
		return '''
			«FOR variable : program.globalVars»
			«IF externDef»extern «ENDIF»«varGenerationHelper.generateGlobalVariableDefinition(variable)»;
			«ENDFOR»
			«FOR proc : program.processes»
			«FOR variable: proc.variables»
			«IF externDef»extern «ENDIF»«varGenerationHelper.generateProcessVariableDefinition(variable)»;
			«ENDFOR»
			«ENDFOR»
		'''
	}

	def generatePorts(boolean externDef) {
		return '''
			«FOR reg : program.ports»
			«IF externDef»extern «ENDIF»«portGenerationHelper.generatePortVariableDefinition(reg)»;
			«ENDFOR»
		'''
	}
	
	def generateClockConst() {
		return '''#define «CLOCK_CONST_NAME» «LiteralGenerationUtil.translateClockDefinition(program.clock)»'''
	}

	def generateConstants() {
		return '''
			«FOR constant : program.consts»
			«constGenerationHelper.generateConstantDefinition(constant)»
			«ENDFOR»
		'''
	}

	def generateEnums() {
		return '''
			«FOR en : program.enums»
			«constGenerationHelper.generateEnumDefinition(en)»
			«ENDFOR»
		'''
	}
	
	def generateTimeVariableDefinitions(boolean extern) {
		return '''
		«IF extern»extern «ENDIF»INT32_U «CUR_TIME_NAME»;
		«IF extern»extern «ENDIF»INT32_U «NEXT_TIME_NAME»;
		'''
	}
	
}
