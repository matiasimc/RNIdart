# Reglas de inferencia

En este archivo se explican las reglas de inferencia y se ejemplifica su aplicación.

## Consideraciones

Primero, es necesario notar que la inferencia realizada en este trabajo no es "inferencia de tipos de dos facectas", debido a que Dart provee la inferencia de tipos de la faceta privada. Por lo tanto, el problema de inferencia se denomina "inferencia de faceta pública dada la faceta privada"

## Sintaxis

La sintaxis del lenguaje fue adaptada de type-based relaxed noninterference, extendida con características de lenguajes imperativos, variables, asignaciones e instrucciones condicionales.

```
e ::= v | e;e | e = e | if e then e else e | while e do e | e.m(e) | m(x)(e;return e)
v ::= DV | x | [z: U => list(m(x)e)]
U ::= O | TVar
O ::= Obj(TVar). [list(m: U -> U)]
x variable
m method label
U public facet
DV Dart primitive value
```

## Contexto

La adición de referencias hace necesario introducir un mecanismo de store de variables y posiciones de memoria M. Básicamente, cuando una variable es inicializada, se agrega a un diccionario `x -> int`, que indica la posición en memoria apuntada por determinada variable. Otro diccionario `int -> v` indica el valor en determinada posición en memoria.

Para realizar inferencia en un lenguaje con referencias, es necesario utilizar lo que se llama "program counter para seguridad" (pc), el cual indica el contexto de seguridad en el cual se ejecuta una instrucción.

Por último, debido a las consideraciones iniciales, se agrega la faceta privada al contexto.

## Reglas de inferencia

Se muestran las reglas de inferencia y luego una explicación de cada una de ellas, con ejemplos.

```
(imp)

Γ, M, pc, pt |- e1 : t1 | C1
Γ, M, pc, pt |- e2 : t2 | C2
--------------------------------
Γ, M, pc |- e1;e2 : t | C2 U C1


(assn)

Γ, M, pc, pt |- e1 : t1 | C1
Γ, M, pc, pt |- e2 : t2 | C2
----------------------------------------------------
Γ, M, pc |- e1 = e2 : t | {t1 v pc <: t2} U C1 U C2


(cond)

Γ, M, pc, pt |- e1 : t1 | C1  
Γ, M, pc1, pt |- e2 : t2 | C2
Γ, M, pc1, pt |- e3 : t3 | C3
-----------------------------------------------------------------------
Γ, M, pc, pt |- if e1 then e2 else e3 : t | C3 U C2 U {t1 <: pc1} U C1
   

(loop)

Γ, M, pc, pt |- e1 : t1 | C1
Γ, M, pc1, pt |- e2 : t2 | C2
---------------------------------------------------------------
Γ, M, pc, pt |- while e1 do e2 : t1 v t2 | C2 U {t1 <: pc1} U C1
      
      
(call)

Γ, M, pc, pt |- e1 : t1 | C1
Γ, M, pc, pt |- e2 : t2 | C2
------------------------------------------------------------------
Γ, M, pc, pt |- e1.m(e2) : t3 | {t1 <: [[m: t2 -> t3]]} U C2 U C1


(return)

Γ, M, pc, pt |- m : t1 -> t2 | C1
Γ, M, pc, pt |- e2 : t3 | C2
------------------------------------------------------------
Γ, M, pc, pt |- m(x)(e1;return e2) : t | {t1 = t3} U C2 U C1

    
(subtyping)

     Γ, M, pc, pt |- e : t | C1
--------------------------------------
Γ, M, pc, pt |- e : t | {pt <: t} U C1
```

### Secuencia de instrucciones (imp)

Esta regla representa el comportamiento de una secuencia de instrucciones, indicando que el set de constraints que se genera es la unión de las constraints generadas por cada instrucción (o set de instrucciones).

### Asignación (assn)

Esta regla representa la generación de constraints en una instrucción de asignación. Por ejemplo:

```javascript
@low void foo(@StringSplit String a) {
   @T String b = a;
}
```

Genera la constraint `{@T v @low <: @StringSplit}`. Aquí es importante notar que @low depende del contexto. En este caso, corresponde a @String.

Dependiendo de los valores de @T, el programa puede estar mal tipado.

- Si `@T = @High`, entonces `@High v @low = @High` y `{@High <: @StringSplit}` es una constraint inválida.
- Si `@T <: @StringSplit`, entonces cualquier programa es válido.
- Si `@T` es indeterminado o por inferir, la constraint es `@T <: @StringSplit`, que debe ser resuelta en conjunto con las demás constraint del programa. En este caso, lo correcto es inferir `@T = @StringSplit`.

### Condicional If (cond)

Esta regla representa la generación de constraints en una instrucción condicional. Por ejemplo:

### Loop While (loop)

Esta regla representa la generación de constraints en una instrucción while. Por ejemplo:

### Llamada a método (call)

Esta regla representa la generación de constraints en una llamada a método. Por ejemplo:

### Retorno de un método (return)

Esta regla representa la generación de constraints para el tipo de retorno de un método. Por ejemplo:

### Relación entre facetas (subtyping)

Esta regla indica la relación de subtyping entre la faceta pública y la faceta privada, y en la práctica significa que si una variable de tipo no tiene ninguna constraint asociada, entonces el tipo inferido será @low. Por ejemplo:
