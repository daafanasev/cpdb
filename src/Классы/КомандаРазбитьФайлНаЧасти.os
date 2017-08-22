///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем Лог;
Перем	УдалитьИсточник;

// Интерфейсная процедура, выполняет регистрацию команды и настройку парсера командной строки
//   
// Параметры:
//   ИмяКоманды 	- Строка										- Имя регистрируемой команды
//   Парсер 		- ПарсерАргументовКоманднойСтроки (cmdline)		- Парсер командной строки
//
Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Разбить файл на части указанного размера (по умолчанию 50 Мб)");
	
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-params",
		"Файлы JSON содержащие значения параметров,
		|могут быть указаны несколько файлов разделенные "";""
		|(параметры командной строки имеют более высокий приоритет)");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды,
		"-src",
		"Путь к исходному локальному файлу для разбиения");
	
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды,
		"-arc",
		"Имя файла архива (не обязательный, по умолчанию <имя исходного файла>.7z)");
		
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды,
		"-list",
		"Имя файла, списка томов архива (не обязательный, по умолчанию <имя исходного файла>.split)");
		
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды,
		"-vol",
		"Размер части {<g>, <m>, <b>} (по умолчанию 50m)");
		
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды,
		"-hash",
		"Рассчитывать MD5-хеши файлов частей");
	
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды,
		"-hash-file",
		"Имя файла, списка хэшей томов архива  (не обязательный, по умолчанию <имя исходного файла>.hash)");
		
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды,
		"-delsrc",
		"Удалить исходный файл после выполнения операции");
	
	Парсер.ДобавитьКоманду(ОписаниеКоманды);
	
КонецПроцедуры //ЗарегистрироватьКоманду()

// Интерфейсная процедура, выполняет текущую команду
//   
// Параметры:
//   ПараметрыКоманды 	- Соответствие						- Соответствие параметров команды и их значений
//
// Возвращаемое значение:
//	Число - код возврата команды
//
Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
	
	ЗапускПриложений.ПрочитатьПараметрыКомандыИзФайла(ПараметрыКоманды["-params"], ПараметрыКоманды);
	
	ПутьКФайлу				= ПараметрыКоманды["-src"];
	ИмяАрхива				= ПараметрыКоманды["-arc"];
	ИмяСпискаФайлов			= ПараметрыКоманды["-list"];
	УдалитьИсточник			= ПараметрыКоманды["-delsrc"];
	РазбитьНаТома			= ПараметрыКоманды["-vol"];
	РассчитыватьХеши		= ПараметрыКоманды["-hash"];
	ИмяФайлаХэшей			= ПараметрыКоманды["-hash-file"];
	
	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();
	
	РассчитыватьХеши = ?(РассчитыватьХеши = Неопределено, Ложь, Истина);

	Если ПустаяСтрока(ПутьКФайлу) Тогда
		Лог.Ошибка("Не указан путь к файлу для разбиения");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;
	
	ПутьК7ЗИП = ЗапускПриложений.Найти7Zip();
	
	Если НЕ ЗначениеЗаполнено(ПутьК7ЗИП) Тогда
		Лог.Ошибка("7-Zip не найден");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	КоличествоОтправляемыхФайлов = ЗапаковатьВАрхив(ПутьК7ЗИП
												  , ПутьКФайлу
												  , ИмяАрхива
												  , ИмяСпискаФайлов
												  , РазбитьНаТома
												  , РассчитыватьХеши
												  , ИмяФайлаХэшей);
	
	SetEnvironmentVariable("Amount_splitted_parts", КоличествоОтправляемыхФайлов);
	
	Возврат ВозможныйРезультат.Успех;
	
КонецФункции //ВыполнитьКоманду()

//***************************************
// Основная функция упаковки/разбиения файла
//***************************************
Функция ЗапаковатьВАрхив(Знач Архиватор
					   , Знач ПутьКФайлу
					   , Знач ИмяАрхива = Неопределено
					   , Знач ИмяСпискаФайлов = Неопределено
					   , Знач ПараметрыАрхива = Неопределено
					   , РассчитыватьХеши = Ложь
					   , Знач ИмяФайлаХэшей = Неопределено)
					   
	ДанныеИсхФайла = Новый Файл(ПутьКФайлу);

	Если НЕ ЗначениеЗаполнено(ИмяАрхива) Тогда
		ИмяАрхива = ДанныеИсхФайла.ИмяБезРасширения + ".7z";
	КонецЕсли;
	Если НЕ ЗначениеЗаполнено(ИмяСпискаФайлов) Тогда
		ИмяСпискаФайлов = ОбъединитьПути(ДанныеИсхФайла.Путь, ДанныеИсхФайла.ИмяБезРасширения + ".split");
	КонецЕсли;
	Если НЕ ЗначениеЗаполнено(ИмяФайлаХэшей) Тогда
		ИмяФайлаХэшей = ОбъединитьПути(ДанныеИсхФайла.Путь, ДанныеИсхФайла.ИмяБезРасширения + ".hash");
	КонецЕсли;

	ИмяФайлаОшибокАрхивации = ДанныеИсхФайла.Путь + "7z_error_messages.txt";

	КомандаАрхиватора = СтрШаблон("""%1"" a  ""%4"" ""%3"" -t7z -v%2 -mx0", Архиватор, 
		?(ЗначениеЗаполнено(ПараметрыАрхива), ПараметрыАрхива, "50m"),
		ПутьКФайлу,
		ИмяАрхива);
	
	
	Лог.Отладка("команда архиватора: " + КомандаАрхиватора);
	КодВозврата = 0;
	ЗапуститьПриложение(КомандаАрхиватора, ДанныеИсхФайла.Путь, истина, КодВозврата);

	Если КодВозврата = 0 Тогда
		МассивФайловЧастей = НайтиФайлы(ДанныеИсхФайла.Путь, ИмяАрхива + ".???", Ложь);
		Лог.Отладка("Всего частей: " + МассивФайловЧастей.Количество());

		Если УдалитьИсточник Тогда
			УдалитьФайлы(ПутьКФайлу);
		КонецЕсли;

		ЗаписьСписка = Новый ЗаписьТекста(ИмяСпискаФайлов, КодировкаТекста.UTF8, , Ложь);

		Если РассчитыватьХеши Тогда
			ЗаписьХешей = Новый ЗаписьТекста(ИмяФайлаХэшей, КодировкаТекста.UTF8, , Ложь);
			РасчетХешей = Новый ХешированиеДанных(ХешФункция.MD5);
		КонецЕсли;

		Для каждого ФайлЧасти Из МассивФайловЧастей Цикл
			ЗаписьСписка.ЗаписатьСтроку(ФайлЧасти.Имя);

			Если РассчитыватьХеши Тогда
				РасчетХешей.ДобавитьФайл(ФайлЧасти.ПолноеИмя);
				ЗаписьХешей.ЗаписатьСтроку(СтрШаблон("%1 %2", ФайлЧасти.Имя, РасчетХешей.ХешСуммаСтрокой));
				РасчетХешей.Очистить();
			КонецЕсли;

		КонецЦикла;
		ЗаписьСписка.Закрыть();

		Если РассчитыватьХеши Тогда
			ЗаписьХешей.Закрыть();
		КонецЕсли;
		Возврат МассивФайловЧастей.Количество();
	Иначе

		Лог.Ошибка("Архивирование завершилось с ошибкой. Код возврата " + КодВозврата);
		ФайлОшибокАрх = Новый Файл(ИмяФайлаОшибокАрхивации);
		Если ФайлОшибокАрх.Существует() Тогда
			ЧтениеФайла = Новый ЧтениеТекста(ИмяФайлаОшибокАрхивации);
			СтрокаФайлаОшибок = ЧтениеФайла.ПрочитатьСтроку();
			Пока СтрокаФайлаОшибок <> Неопределено Цикл
				Лог.Ошибка(СтрокаФайлаОшибок);
				СтрокаФайлаОшибок = ЧтениеФайла.ПрочитатьСтроку();
			КонецЦикла;
			ЧтениеФайла.Закрыть();
			УдалитьФайлы(ИмяФайлаОшибокАрхивации);
		КонецЕсли;

		Возврат 0;
	КонецЕсли
КонецФункции // ЗапаковатьВАрхив()

Лог = Логирование.ПолучитьЛог("ktb.app.cpdb");