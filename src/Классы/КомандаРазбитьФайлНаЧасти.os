///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем Лог;
Перем	УдалитьИсточник;

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Разбить файл на части указанного размера (по умолчанию 50 Мб)");
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ПутьКФайлу", "Путь к исходному локальному файлу для разбиения");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-v","Размер части");
	
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-delsource",	"Удалить исходный файл после выполнения операции");
	
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры

Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
	
	ПутьКФайлу				= ПараметрыКоманды["ПутьКФайлу"];
	УдалитьИсточник			= ПараметрыКоманды["-delsource"];
	РазбитьНаТома			= ПараметрыКоманды["-v"];
	
	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();
	
	Если ПустаяСтрока(ПутьКФайлу) Тогда
		Лог.Ошибка("Не указан путь к файлу для разбиения");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;
	
	ПутьК7ЗИП = Найти7Zip();
	
	Если НЕ ЗначениеЗаполнено(ПутьК7ЗИП) Тогда
		Лог.Ошибка("7-Zip не найден");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Если ЗначениеЗаполнено(РазбитьНаТома) Тогда
		КоличествоОтправляемыхФайлов = ЗапаковатьВАрхив(ПутьК7ЗИП,ПутьКФайлу, РазбитьНаТома);
	Иначе
		КоличествоОтправляемыхФайлов = ЗапаковатьВАрхив(ПутьК7ЗИП,ПутьКФайлу);
	КонецЕсли;
	
	SetEnvironmentVariable("Amount_splitted_parts", КоличествоОтправляемыхФайлов);
	
	Возврат ВозможныйРезультат.Успех;
КонецФункции


Функция Найти7ZIP()
	// Предполагаем, что для X64_86 7-Zip будет 64-битный
//	ПутьПрограмм = ПолучитьПеременнуюСреды("PROGRAMFILESW6432");
//	Если НЕ ЗначениеЗаполнено(ПутьПрограмм) Тогда
//		ПутьПрограмм = ПолучитьПеременнуюСреды("PROGRAMFILES");
//	КонецЕсли;
	
//	Сообщить("Путь поиска: " + ПутьПрограмм);
	Массив7ZIP = НайтиФайлы("C:\Program Files", "7z.exe", True);
	Если Массив7ZIP.Количество() = 0 Тогда
		Возврат Неопределено;
	Иначе
		Возврат Массив7ZIP[0].ПолноеИмя;
	КонецЕсли;
КонецФункции

Функция ЗапаковатьВАрхив(Знач Архиватор, Знач ПутьКФайлу, Знач ПараметрыАрхива = Неопределено)
	ДанныеИсхФайла = Новый Файл(ПутьКФайлу);
	ИмяАрхива = ДанныеИсхФайла.ИмяБезРасширения + ".7z";
	КомандаАрхиватора = СтрШаблон("""%1"" a  %4 ""%3"" -t7z -v%2", Архиватор, 
		?(ЗначениеЗаполнено(ПараметрыАрхива), ПараметрыАрхива, "50m"),
		ПутьКФайлу,
		ИмяАрхива);
	
	
	Сообщить("команда архиватора: " + КомандаАрхиватора);
	КодВозврата = 0;
	ЗапуститьПриложение(КомандаАрхиватора, ДанныеИсхФайла.Путь, истина, КодВозврата);

	МассивФайловЧастей = НайтиФайлы(ДанныеИсхФайла.Путь, ИмяАрхива + ".???", Ложь);
	Сообщить("Всего частей: " + МассивФайловЧастей.Количество());

	Если УдалитьИсточник Тогда
		УдалитьФайлы(ПутьКФайлу);
	КонецЕсли;

	Возврат МассивФайловЧастей.Количество();
КонецФункции // ЗапаковатьВАрхив(Знач ПутьКФайлу, Знач ПараметрыАрхива)

Лог = Логирование.ПолучитьЛог("ktb.app.copydb");