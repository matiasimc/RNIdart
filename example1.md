# Ejemplo steps

```javascript
Action foo(Student a, Teacher b) {
	a.learnFrom(b);
	return b.teach(a);
}

class Student {
	void learnFrom(Teacher b) {
		print("I'm learning from ${b.getName()}!");
	}
}

class Teacher {
	Action teach(Student a) {
		return new TeachAction(this, a);
	}
	
	String getName() {
		return this.name;
	}
}
```

## Paso 1: Generar constraints considerando públicos argumentos y tipos de retorno de métodos llamados en el cuerpo del método.

(se omiten posiciones en memoria del store para simplificar)
(me di cuenta que olvidé generar constraints para la expresión de retorno y el tipo de retorno del método, pero se entiende la idea)

```
Action foo(Student a, Teacher b) { ->

M = {a = t1, b = t2}
C = {}
pc = t_pc

a.learnFrom(b); ->

M = {a -> t1, b -> t2}
C = {(t1 <: {learnFrom: t3 -> t4})}

return b.teach(a); ->

M = {a = t1, b = t2}
C = {(t2 <: {teach: t5 -> t6}), (t1 <: {learnFrom: t3 -> t4})}

...

void learnFrom(Teacher b) { ->

M = {b = t7}
C = {(t2 <: {teach: t5 -> t6}), (t1 <: {learnFrom: t3 -> t4})}

print("I'm learning from ${b.getName()}!"); ->

M = {b = t7}
C = {(t7 <: {getName: t8 -> t9}), (t2 <: {teach: t5 -> t6}), (t1 <: {learnFrom: t3 -> t4})}

...

Action teach(Student a) { ->

M = {a = t10}
C = {(t7 <: {getName: t8 -> t9}), (t2 <: {teach: t5 -> t6}), (t1 <: {learnFrom: t3 -> t4})}

return new TeachAction(this, a); ->

M = {a = t10}
C = {(t7 <: {getName: t8 -> t9}), (t2 <: {teach: t5 -> t6}), (t1 <: {learnFrom: t3 -> t4})}

String getName() { ->

M = {}
C = {(t7 <: {getName: t8 -> t9}), (t2 <: {teach: t5 -> t6}), (t1 <: {learnFrom: t3 -> t4})}

return this.name; -> 

M = {}
C = {(t7 <: {getName: t8 -> t9}), (t2 <: {teach: t5 -> t6}), (t1 <: {learnFrom: t3 -> t4})}
```

Resolviendo las constraints:

- Como t8 y t9 no tienen constraint asociada, t8 <: @low, t9 <: @low, t7 <: {getName: @low -> @low}
- Lo mismo con t5 y t6: t5 <: @low, t6: @low, t2 <: {teach: t5 -> t6}
- Y con t3 y t4: t3 <: @low, t4 <: @low, t1 <: {learnFrom: @low -> @low}

Anotando el programa, queda esto:

```javascript
@Action Action foo(@StudentLearnFrom Student a, @TeacherTeach Teacher b) {
	a.learnFrom(b);
	return b.teach(a);
}

class Student {
	@low void learnFrom(@TeacherGetName Teacher b) {
		print("I'm learning from ${b.getName()}!");
	}
}

class Teacher {
	@Action Action teach(@Student Student a) {
		return new TeachAction(this, a);
	}
	
	@String String getName() {
		return this.name;
	}
}

abstract class StudentLearnFrom {
	void learnFrom(Student a);
}

abstract class TeacherTeach {
	Action teach(Student a);
}

abstract class TeacherGetName {
	String getName();
}
```
## Paso 2: Basado esta inferencia simple, realizar un refinamiento ahora que los parámetros de cada método si están anotados

Aquí, notemos que la llamada al método teach ahora recibe un argumento de faceta privada @StudentLearnFrom en lugar de @Student, por lo que es posible refinar la firma de ese método. Lo mismo para el método learnFrom. Para ello, recorremos el código y vamos viendo las llamadas a métodos:

a.learnFrom(b); ->

Se genera la constraint (t1 <: @TeacherGetName ^ @TeacherTeach), que corresponde al meet (join?) entre la faceta del parámetro de "learnFrom" inferida en el paso 1 y la faceta del argumento inferida en el paso 1.

b.teach(a); ->

Se genera la constraint (t2 <: @Student ^ @StudentLearnFrom).

Luego, resolviendo las nuevas constraints, se tiene la versión final del código anotado:

```javascript
@Action Action foo(@StudentLearnFrom Student a, @TeacherTeach Teacher b) {
	a.learnFrom(b);
	return b.teach(a);
}

class Student {
	@low void learnFrom(@TeacherGetNameTeach Teacher b) {
		print("I'm learning from ${b.getName()}!");
	}
}

class Teacher {
	@Action Action teach(@Student Student a) {
		return new TeachAction(this, a);
	}
	
	@String String getName() {
		return this.name;
	}
}

abstract class StudentLearnFrom {
	void learnFrom(Student a);
}

abstract class TeacherTeach {
	Action teach(Student a);
}

abstract class TeacherGetName {
	String getName();
}

abstract class TeacherGetNameTeach {
	String getName();
	Action teach(Student a);
}
```
